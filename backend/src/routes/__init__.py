from fastapi import APIRouter
from .general import router as general_router
from .sauna import router as sauna_router
from .chat import router as chat_router

api_router = APIRouter()
api_router.include_router(general_router, tags=["General"])
api_router.include_router(sauna_router, prefix="/sauna", tags=["Sauna"])
api_router.include_router(chat_router, prefix="/chat", tags=["Chat"])