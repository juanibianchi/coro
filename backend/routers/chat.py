"""Chat router with all API endpoints."""

import asyncio
import logging
import time
from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, HTTPException
from backend.models.schemas import (
    ChatRequest,
    SingleChatRequest,
    ChatResponse,
    ModelResponse,
    ModelsResponse,
    ModelInfo,
    HealthResponse
)
from backend.config import config
from backend.services.gemini_service import GeminiService
from backend.services.groq_service import GroqService
from backend.services.deepseek_service import DeepSeekService

logger = logging.getLogger(__name__)

router = APIRouter()

# Initialize services
gemini_service = GeminiService()
groq_service = GroqService()
deepseek_service = DeepSeekService()


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """
    Health check endpoint for monitoring.

    Returns:
        HealthResponse with status and timestamp
    """
    return HealthResponse(
        status="ok",
        timestamp=datetime.now(timezone.utc).isoformat()
    )


@router.get("/models", response_model=ModelsResponse)
async def list_models() -> ModelsResponse:
    """
    List all available models with metadata.

    Returns:
        ModelsResponse with list of available models
    """
    models = [
        ModelInfo(
            id=model_data["id"],
            name=model_data["name"],
            provider=model_data["provider"],
            cost=model_data["cost"]
        )
        for model_data in config.MODELS.values()
    ]

    return ModelsResponse(models=models)


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    """
    Send prompt to multiple models in parallel.

    Args:
        request: ChatRequest with prompt, models, temperature, and max_tokens

    Returns:
        ChatResponse with responses from all requested models
    """
    logger.info(f"Chat request received for models: {request.models}")
    start_time = time.time()

    # Validate model IDs
    invalid_models = [m for m in request.models if m not in config.MODELS]
    if invalid_models:
        logger.warning(f"Invalid model IDs requested: {invalid_models}")
        raise HTTPException(
            status_code=400,
            detail=f"Invalid model IDs: {', '.join(invalid_models)}"
        )

    # Create tasks for parallel execution
    tasks = []
    for model_id in request.models:
        task = _generate_for_model(
            model_id,
            request.prompt,
            request.temperature,
            request.max_tokens
        )
        tasks.append(task)

    # Execute all tasks in parallel
    responses = await asyncio.gather(*tasks)

    # Calculate total latency
    total_latency_ms = int((time.time() - start_time) * 1000)

    # Log results
    success_count = sum(1 for r in responses if r.error is None)
    error_count = len(responses) - success_count
    logger.info(f"Chat completed: {success_count} succeeded, {error_count} failed, total latency: {total_latency_ms}ms")

    return ChatResponse(
        responses=responses,
        total_latency_ms=total_latency_ms
    )


@router.post("/chat/{model_id}", response_model=ModelResponse)
async def chat_single(model_id: str, request: SingleChatRequest) -> ModelResponse:
    """
    Send prompt to a single model.

    Args:
        model_id: The ID of the model to query
        request: SingleChatRequest with prompt, temperature, and max_tokens

    Returns:
        ModelResponse with the model's response
    """
    # Validate model ID
    if model_id not in config.MODELS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid model ID: {model_id}"
        )

    # Generate response
    response = await _generate_for_model(
        model_id,
        request.prompt,
        request.temperature,
        request.max_tokens
    )

    return response


async def _generate_for_model(
    model_id: str,
    prompt: str,
    temperature: float,
    max_tokens: int
) -> ModelResponse:
    """
    Generate a response for a specific model.

    Args:
        model_id: The model ID
        prompt: The prompt to send
        temperature: Temperature for generation
        max_tokens: Maximum tokens to generate

    Returns:
        ModelResponse with the generated response or error
    """
    try:
        if model_id == "gemini":
            return await gemini_service.generate(prompt, temperature, max_tokens)

        elif model_id in ["llama-70b", "llama-8b", "mixtral"]:
            return await groq_service.generate(model_id, prompt, temperature, max_tokens)

        elif model_id == "deepseek":
            return await deepseek_service.generate(prompt, temperature, max_tokens)

        else:
            # This should never happen due to validation, but just in case
            return ModelResponse(
                model=model_id,
                response="",
                tokens=None,
                latency_ms=0,
                error=f"Unknown model: {model_id}"
            )

    except Exception as e:
        # Catch any unexpected errors
        return ModelResponse(
            model=model_id,
            response="",
            tokens=None,
            latency_ms=0,
            error=f"Unexpected error: {str(e)}"
        )
