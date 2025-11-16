from contextlib import asynccontextmanager
from fastapi import FastAPI
from backend.src.services.llm import initialize_llm_components
from backend.src.services.recommendation import load_recommendation_model
from backend.src.utils.logger import get_logger

logger = get_logger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Handles application startup and shutdown events.
    """
    logger.info("--- Application Startup ---")
    load_recommendation_model()
    initialize_llm_components()
    yield
    logger.info("--- Application Shutdown ---")