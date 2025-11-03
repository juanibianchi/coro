"""CORO - Multi-LLM Chat Application Backend

FastAPI application for comparing responses from multiple AI models.
"""

import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routers import chat
from backend.config import config

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="CORO API",
    description="Multi-LLM chat application for comparing AI model responses",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
allowed_origins = config.get_allowed_origins()
allow_credentials = config.should_allow_credentials(allowed_origins)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

# Include routers
app.include_router(chat.router, tags=["chat"])


@app.on_event("startup")
async def startup_event():
    """Validate configuration on startup."""
    logger.info("Starting CORO API server...")

    # Initialize HTTP client for connection pooling
    from backend.utils.performance import get_http_client
    get_http_client()
    logger.info("Initialized HTTP client with connection pooling")

    # Log available models
    logger.info(f"Available models: {', '.join(config.MODELS.keys())}")

    # Check API keys status
    keys_status = config.get_api_keys_status()
    configured_keys = [key for key, status in keys_status.items() if status]
    missing_keys = [key for key, status in keys_status.items() if not status]

    if configured_keys:
        logger.info(f"✓ Configured API keys: {', '.join(configured_keys)}")

    if missing_keys:
        logger.warning(f"⚠ Missing API keys: {', '.join(missing_keys)}")
        logger.warning("Some models may not work without proper API keys configured.")

    logger.info("CORO API server started successfully")


@app.on_event("shutdown")
async def shutdown_event():
    """Clean up resources on shutdown."""
    logger.info("Shutting down CORO API server...")

    # Close HTTP client
    from backend.utils.performance import close_http_client
    await close_http_client()

    logger.info("CORO API server shut down successfully")


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": "CORO API",
        "version": "1.0.0",
        "description": "Multi-LLM chat comparison service",
        "docs": "/docs",
        "health": "/health",
        "models": "/models"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "backend.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
