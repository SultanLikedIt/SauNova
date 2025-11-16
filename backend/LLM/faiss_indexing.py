from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from backend.src.utils.logger import get_logger
from pathlib import Path
from backend.config import chunking_model_name

#TODO use custom embeddings later

# Initialize logger
logger = get_logger(__name__)

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent  # adjust if inside src/
DATA_DIR = PROJECT_ROOT / "backend" / "LLM" / "data" / "faiss_index"
def build_faiss_index(chunks,model_name=chunking_model_name):

    if not chunks:
        logger.error("No chunks provided to build the FAISS index.")
        return None

    embedding_model = HuggingFaceEmbeddings(model_name=model_name)

    try:
        faiss_index = FAISS.from_documents(chunks, embedding_model)
        logger.info("FAISS index built successfully.")
    except Exception as e:
        logger.error(f"Error building FAISS index: {e}")
        return None
    return faiss_index


def save_faiss_index(faiss_index, path=Path("data")/"faiss_index"):

    if not path.parent.exists():
        Path.mkdir(parents=True,exist_ok=True)
    try:
        faiss_index.save_local(str(path))
        logger.info(f"FAISS index saved successfully at {path}.")
    except Exception as e:
        logger.error(f"Error saving FAISS index: {e}")


def load_faiss_index(path=DATA_DIR, model_name=chunking_model_name):
    path = Path(path)
    logger.debug(f"Attempting to load FAISS index from {path}")

    if not (path / "index.faiss").exists() or not (path / "index.pkl").exists():
        logger.error(f"FAISS index files not found in {path}.")
        return None

    embedding_model = HuggingFaceEmbeddings(model_name=model_name)

    try:
        faiss_index = FAISS.load_local(str(path), embedding_model, allow_dangerous_deserialization=True)
        logger.info(f"FAISS index loaded successfully from {path}.")
        return faiss_index
    except Exception as e:
        logger.error(f"Error loading FAISS index: {e}")
        return None


