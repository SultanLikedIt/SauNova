from langchain_classic.text_splitter import RecursiveCharacterTextSplitter
from backend.src.utils.logger import get_logger

#Initialize logger
logger=get_logger(__name__)

#Function for chunking documents

def chunk_documents(documents, chunk_size=500, chunk_overlap=50):

    if not isinstance(documents,list):
        logger.error("Input documents should be a list of Document objects.")
        return []

    if len(documents)==0:
        logger.warning("No documents to chunk. Returning empty list.")
        return []


    # Text splitter Setup
    text_splitter=RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        length_function=len #For characters
        #TODO use tokenizer-based length function later
    )

    try:
        chunks=text_splitter.split_documents(documents)
    except Exception as e:
        logger.error(f"Error during chunking: {e}")
        return []
    return chunks
