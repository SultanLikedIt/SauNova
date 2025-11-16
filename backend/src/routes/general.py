from backend.src.models.response_models import HealthResponse
from fastapi import APIRouter

router = APIRouter()

@router.get("/", response_model=HealthResponse)
def root() -> HealthResponse:
    return HealthResponse()


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse()