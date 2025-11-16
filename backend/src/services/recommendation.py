from backend.src.core.config import MODEL_PATH, SCALER_PATH
from backend.src.utils.logger import get_logger

logger = get_logger(__name__)
sauna_engine = None

try:
    from backend.predictive_model.neural_network import SaunaRecommendationEngine
    NEURAL_NETWORK_AVAILABLE = True
except ImportError as e:
    logger.warning("Neural network not available: %s", e)
    NEURAL_NETWORK_AVAILABLE = False

def load_recommendation_model():
    """Loads the sauna recommendation model into memory."""
    global sauna_engine
    if NEURAL_NETWORK_AVAILABLE and sauna_engine is None:
        try:
            if MODEL_PATH.exists() and SCALER_PATH.exists():
                sauna_engine = SaunaRecommendationEngine(
                    model_path=str(MODEL_PATH),
                    scaler_path=str(SCALER_PATH)
                )
                logger.info("Sauna recommendation model loaded successfully.")
            else:
                logger.warning("Model or scaler files not found. Recommendation engine disabled.")
        except Exception as e:
            logger.error("Failed to load sauna recommendation model: %s", e)

def get_sauna_engine():
    """Returns the loaded sauna engine instance."""
    return sauna_engine