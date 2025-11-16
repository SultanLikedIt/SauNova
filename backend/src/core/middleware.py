from typing import Optional
from fastapi import Request, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
from starlette.types import ASGIApp
from firebase_admin import auth as fb_auth

from backend.src.utils.logger import get_logger

logger = get_logger(__name__)






async def log_requests(request: Request, call_next):
    """Middleware to log incoming requests and outgoing responses."""
    logger.info("REQ %s %s", request.method, request.url.path)
    response = await call_next(request)
    logger.info("RES %s %s -> %s", request.method, request.url.path, response.status_code)
    return response