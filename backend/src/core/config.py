import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from a .env file
load_dotenv()

# Project Paths
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MODEL_PATH = PROJECT_ROOT /  "predictive_model" / "sauna_recommendation_model.pth"
SCALER_PATH = PROJECT_ROOT /  "predictive_model" / "sauna_scaler.pkl"

# OpenAI API Key
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# LLM Model Names (with safe fallbacks)
try:
    from backend.LLM.config import model_name
    LLM_MODEL_NAME = model_name
except ImportError:
    LLM_MODEL_NAME = "gpt-3.5-turbo" # Example fallback

# CORS Origins
CORS_ALLOW_ORIGINS = [
    "http://localhost",
    "http://localhost:19006",
    "http://127.0.0.1:19006",
    "http://localhost:3000",
    "exp://*",
    "*",  # Adjust for production
]