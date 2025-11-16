import os

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.src.routes import api_router
from backend.src.core.config import CORS_ALLOW_ORIGINS
from backend.src.core.middleware import log_requests
from backend.src.lifespan import lifespan
from dotenv import load_dotenv

load_dotenv()

# Create the FastAPI application instance
app = FastAPI(
    title="Sauna Backend API",
    description="Backend API for the Expo/React Native Sauna app",
    version="0.1.0",
    lifespan=lifespan,  # Manages startup and shutdown events
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOW_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.middleware("http")(log_requests)



# Include the main API router with a prefix
app.include_router(api_router)



if __name__ == "__main__":
    # Entry point for local development
    uvicorn.run("backend.src.main:app", host="0.0.0.0", port=int(os.getenv("PORT")), reload=True)