import os
from dotenv import load_dotenv
from backend.src.utils.logger import get_logger
from operator import itemgetter

# LangChain components
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_core.chat_history import InMemoryChatMessageHistory
from langchain_classic.chains import create_history_aware_retriever, create_retrieval_chain
from langchain_classic.chains.combine_documents import create_stuff_documents_chain
from langchain_core.runnables import RunnablePassthrough, RunnableMap
import tiktoken
from backend.LLM.config import MAX_INPUT_TOKENS, model_name

import json
from typing import AsyncIterator

load_dotenv()
logger = get_logger(__name__)

# Session management
session_store = {}


# TODO: Cloud deployement
def get_session_history(session_id: str):
    if session_id not in session_store:
        session_store[session_id] = InMemoryChatMessageHistory()
    return session_store[session_id]


def clear_session(session_id: str):
    """Clear a specific session's chat history"""
    if session_id in session_store:
        del session_store[session_id]
        logger.info(f"Cleared session: {session_id}")
        return True
    return False


def clear_all_sessions():
    """Clear all sessions (use with caution in production)"""
    session_store.clear()
    logger.info("Cleared all sessions")


def get_active_sessions():
    """Get list of active session IDs"""
    return list(session_store.keys())


# Setting Input Token Limits

def count_tokens(text, model_name):
    try:
        enc = tiktoken.encoding_for_model(model_name)
    except KeyError:
        enc = tiktoken.get_encoding("cl100k_base")
    return len(enc.encode(text))


def enforce_token_limit(text, model_name, max_tokens=MAX_INPUT_TOKENS, ):
    enc = tiktoken.encoding_for_model(model_name)
    tokens = enc.encode(text)
    if len(tokens) > max_tokens:
        truncated = enc.decode(tokens[:max_tokens])
        logger.warning(f"Input truncated from {len(tokens)} to {max_tokens} tokens.")
        return truncated
    return text


def create_qa_chain(faiss_index, model_name, streaming=False, ):
    try:
        if faiss_index is None:
            logger.error("Cannot create QA chain: FAISS index is None")
            return None
            
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            logger.error("Cannot create QA chain: OPENAI_API_KEY not found in environment variables")
            return None
            
        llm = ChatOpenAI(
            model=model_name,
            temperature=0,
            openai_api_key=api_key,
            max_tokens=500,
            streaming=streaming
        )

        retriever = faiss_index.as_retriever(search_kwargs={"k": 3})

        # --- 1. History-aware Retriever Chain ---
        contextualize_q_prompt = ChatPromptTemplate.from_messages([
            ("system",
             "You are a smart assistant specialized in sauna use, wellness, and health benefits. "
             "Your task is to rewrite the latest user question into a clear, standalone question that can be "
             "understood without the conversation history. "
             "Include relevant context from previous messages ONLY if it helps the retriever find relevant information. "
             "Preserve references to sauna effects, health, recovery, longevity, or wellness topics. "
             "Do not add extra information, answers, or explanations — only rewrite the question for retrieval."),
            MessagesPlaceholder(variable_name="chat_history"),
            ("human", "{input}")
        ])
        history_aware_retriever = create_history_aware_retriever(
            llm, retriever, contextualize_q_prompt
        )

        # --- 2. Document Combination Chain (Answer Generation) ---
        qa_prompt = ChatPromptTemplate.from_messages([
            ("system",
             "You are a sauna health assistant designed for the general public. "
             "You answer questions about sauna use, health effects, psychology, recovery, longevity, and related wellness topics.\n\n"
             "Your primary knowledge source is the scientific papers provided to you in the retrieved context. "
             "Follow these rules:\n"
             "1. ALWAYS check the retrieved PDF context first when answering.\n"
             "2. If the retrieved context does NOT contain relevant information, fall back to your general knowledge, "
             "making it clear it is general guidance.\n"
             "3. Never invent or fabricate specific study results.\n"
             "4. Use the ongoing conversation history to interpret pronouns and references.\n"
             "5. Answer in a friendly, simple, and accessible way.\n"
             "6. Provide gentle disclaimers for medical or safety advice.\n"
             "7. If the question is outside sauna/wellness, answer concisely.\n"
             "Be concise, accurate, and grounded in context when possible.\n\nContext: {context}"),
            MessagesPlaceholder(variable_name="chat_history"),
            ("human", "{input}")
        ])
        document_combiner = create_stuff_documents_chain(llm, qa_prompt)

        # --- 3. Final Retrieval Chain ---
        final_retrieval_chain = create_retrieval_chain(
            history_aware_retriever,
            document_combiner,
        )

        # --- 4. Wrap chain to add 'output' key for tracer compatibility ---
        def add_output_key(response):
            """Add 'output' key that mirrors 'answer' for tracer compatibility"""
            response["output"] = response.get("answer", "")
            return response

        final_chain_with_output = final_retrieval_chain | add_output_key

        # --- 5. Chain with Memory ---
        chain_with_memory = RunnableWithMessageHistory(
            final_chain_with_output,
            get_session_history,
            input_messages_key="input",
            history_messages_key="chat_history",
            output_messages_key="output",  # Explicitly specify output key
        )

        logger.info("Modern RAG chain with memory created successfully.")
        return chain_with_memory

    except Exception as e:
        logger.error(f"Error initializing chat chain: {e}", exc_info=True)
        return None


def chat(chat_chain, question: str, session_id: str):
    """
    Send a question to the memory-aware chat chain and return a consistent output including chat history.

    Args:
        chat_chain: The initialized QA chain
        question: User's question
        session_id: REQUIRED unique identifier for the user/session (e.g., user_id, session_token)

    Returns:
        dict: {
            "answer": str,
            "sources": List[str],
            "session_id": str,
            "chat_history": List[dict]  # each item: {"role": "human"/"ai", "content": str}
        }
    """
    if chat_chain is None:
        logger.error("Chat chain is None. Cannot process the question.")
        return None

    try:
        logger.info(f"Processing question: {question} for session: {session_id}")

        question = enforce_token_limit(question, model_name=model_name, max_tokens=MAX_INPUT_TOKENS)

        # Invoke chain with memory
        response = chat_chain.invoke(
            {"input": question},
            config={"configurable": {"session_id": session_id}}
        )

        # Get answer text (now both 'answer' and 'output' should exist)
        answer = response.get("answer") or response.get("output") or ""

        # Get sources (documents)
        sources = response.get("context", [])
        sources_info = set()
        for doc in sources:
            metadata = getattr(doc, "metadata", {})
            source_path = metadata.get("source") or metadata.get("file_name") or "unknown"
            sources_info.add(os.path.basename(source_path))

        # Fetch full chat history from session store
        history_obj = get_session_history(session_id)
        chat_history_list = [{"role": msg.type, "content": msg.content} for msg in history_obj.messages]

        return {
            "answer": answer,
            "sources": list(sources_info),
            "session_id": session_id,
            "chat_history": chat_history_list
        }

    except Exception as e:
        logger.error(f"Error processing chat: {e}")
        return None

