from langchain_community.document_loaders import PyPDFLoader
from pathlib import Path
from backend.src.utils.logger import get_logger

# Initialize logger
logger=get_logger(__name__)

#Function to load PDFs from a list of paths
def load_pdfs(pdf_paths):
    documents = []
    for path in pdf_paths:
        pdf_path=Path(path)
        if not pdf_path.exists():
            logger.warning(f"File {pdf_path} does not exist. Skipping.")
            continue
        loader=PyPDFLoader(str(pdf_path))
        docs=loader.load()
        print(f"[Info] Loaded {len(docs)} documents from {pdf_path.name}")
        documents.extend(docs)
    return documents

# Function to load all PDF paths from a folder
def load_from_folder(folder_path):
    folder=Path(folder_path)
    pdf_files=list(folder.glob("*.pdf"))
    if not pdf_files:
        logger.warning(f"No PDF files found in folder {folder_path}.")
        return []
    return load_pdfs([str(f) for f in pdf_files])