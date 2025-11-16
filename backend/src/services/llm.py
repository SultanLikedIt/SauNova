from backend.src.core.config import OPENAI_API_KEY, LLM_MODEL_NAME
from backend.src.utils.logger import get_logger

logger = get_logger(__name__)
faiss_index = None
qa_chain = None
qa_chain_streaming = None

try:
    from backend.LLM.faiss_indexing import load_faiss_index
    from backend.LLM.qa import create_qa_chain

    LLM_AVAILABLE = True
except ImportError as e:
    logger.warning("LLM components not available: %s", e)
    LLM_AVAILABLE = False

def get_llm_components():
    return {
        "faiss_index": faiss_index,
        "qa_chain": qa_chain,
        "qa_chain_streaming": qa_chain_streaming
    }

def initialize_llm_components():
    """Initializes the FAISS index and QA chains."""
    global faiss_index, qa_chain, qa_chain_streaming

    if not LLM_AVAILABLE:
        logger.error("LLM components are not available. Chat functionality will be disabled.")
        return

    if not OPENAI_API_KEY:
        logger.error("OPENAI_API_KEY not found. Chat functionality will be disabled.")
        return

    logger.info("Loading FAISS index...")
    faiss_index = load_faiss_index()
    if faiss_index is None:
        logger.error("Failed to load FAISS index. Chat functionality disabled.")
        return

    logger.info("Creating QA chains...")
    qa_chain = create_qa_chain(faiss_index, model_name=LLM_MODEL_NAME)
    qa_chain_streaming = create_qa_chain(faiss_index, model_name=LLM_MODEL_NAME, streaming=True)

    if qa_chain and qa_chain_streaming:
        logger.info("LLM components initialized successfully.")
    else:
        logger.error("Failed to create one or more QA chains.")


def get_qa_chains():
    """Returns the loaded QA chains."""
    return qa_chain, qa_chain_streaming