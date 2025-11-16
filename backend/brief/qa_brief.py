import os
from dotenv import load_dotenv
from backend.src.utils.logger import get_logger
# LangChain components
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate

from langchain_core.chat_history import InMemoryChatMessageHistory

from langchain_classic import LLMChain

load_dotenv()
logger = get_logger(__name__)

# Session management
session_store = {}


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


#belirli intervallerle fenix'ten data çek. Hepsiyle matplotlib yap. Image'ı cloud'a at. CLoud'dan çekip modele feedle.


def brief_setup(model_name):
    try:
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            logger.error("Cannot create QA chain: OPENAI_API_KEY not found in environment variables")
            return None

        llm = ChatOpenAI(
            model=model_name,
            temperature=0,
            openai_api_key=api_key,
        )
        prompt = ChatPromptTemplate.from_messages([
            ("system",
             "You are an AI sauna assistant. Generate exactly 4 lines for a sauna session summary in this format and nothing else. Use numbers if necessary. The time is on seconds, temperature is in Celsius, and humidity is in percentage (%).\n\n"
             "Do not add extra commentary or introductions. Make every line engaging and exciting for the user.\n\n"
             "Line 1: Identify and describe the löyly moments in the session graph.\n\n"
             "Line 2: Evaluate the session intensity (intense/moderate/comforting) based on temperature, humidity, and duration.\n\n"
             "Line 3: Comment on whether the temperature curve was stable or fluctuating.\n\n"
             "Line 4: Provide an insight about the humidity pattern during the session.")
            ,
            ("human", "{input}")
        ])
        chain = LLMChain(
            llm=llm,
            prompt=prompt,
            output_key="answer"
        )

        logger.info("Modern RAG chain with memory created successfully.")
        return chain

    except Exception as e:
        logger.error(f"Error initializing chat chain: {e}", exc_info=True)
        return None


def provide_brief(chat_chain, question: str, session_id: str):
    if chat_chain is None:
        logger.error("Chat chain is None. Cannot process the question.")
        return None

    try:
        # encode image
        #import base64
        #image_b64 = base64.b64encode(image_bytes).decode()
        #image_url = f"data:image/png;base64,{image_b64}"

        response = chat_chain.invoke(
            {
                "input": [
                    {"type": "text", "text": question},
                    #{"type": "image_url", "image_url": image_url},
                ]
            },
            config={"configurable": {"session_id": session_id}}
        )

        return {
            "answer": response.get("answer"),
            "session_id": session_id,
        }

    except Exception as e:
        logger.error(f"Error processing chat: {e}")
        return None
