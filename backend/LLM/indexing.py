from src.utils.logger import get_logger
from src.embeddings.faiss_indexing import save_faiss_index, build_faiss_index,load_faiss_index
from src.loaders.pdf_loader import load_from_folder, load_pdfs
from src.utils.chunking import chunk_documents

def main():
    # Initialize logger
    logger = get_logger(__name__)

    # Load documents from folder
    folder_path = "data/raw_data"
    documents = load_from_folder(folder_path)

    if not documents:
        logger.error("No documents loaded. Exiting.")
        return

    # Chunk documents
    chunks = chunk_documents(documents, chunk_size=500, chunk_overlap=50)

    if not chunks:
        logger.error("No chunks created. Exiting.")
        return

    # Build FAISS index
    faiss_index = build_faiss_index(chunks)

    if not faiss_index:
        logger.error("FAISS index could not be built. Exiting.")
        return

    # Save FAISS index
    save_faiss_index(faiss_index)
    logger.info("FAISS index creation and saving completed successfully.")

if __name__ == "__main__":
    main()
    load_faiss_index()