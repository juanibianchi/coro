"""Chat router with all API endpoints."""

import asyncio
import logging
import time
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from backend.models.schemas import (
    ChatRequest,
    SingleChatRequest,
    ChatResponse,
    ModelResponse,
    ModelsResponse,
    ModelInfo,
    HealthResponse,
    SearchContext,
)
from backend.config import config
from backend.services.gemini_service import GeminiService
from backend.services.groq_service import GroqService
from backend.services.deepseek_service import DeepSeekService
from backend.services.cerebras_service import cerebras_service
from backend.models.error_codes import ErrorCode
from backend.services.rate_limiter import enforce_rate_limit

logger = logging.getLogger(__name__)

router = APIRouter()

# Security dependency
auth_scheme = HTTPBearer(auto_error=False)


def require_api_token(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(auth_scheme)
) -> None:
    """
    Enforce bearer token authentication when CORO_API_TOKEN is configured.

    Allows unauthenticated access only when no token is set, which is useful for
    local development or personal experiments.
    """
    if not config.CORO_API_TOKEN:
        return

    if (
        not credentials
        or credentials.scheme.lower() != "bearer"
        or credentials.credentials != config.CORO_API_TOKEN
    ):
        logger.warning("Unauthorized access attempt detected")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "message": "Unauthorized",
                "error_code": ErrorCode.UNAUTHORIZED.value,
            },
        )


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
async def chat(
    request: ChatRequest,
    _: None = Depends(require_api_token),
    __: None = Depends(enforce_rate_limit),
) -> ChatResponse:
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

    override_keys = request.api_overrides or {}
    system_prompt = _compose_system_prompt(
        guide=request.conversation_guide,
        search_context=request.search_context,
    )

    # Create tasks for parallel execution
    tasks = []
    for model_id in request.models:
        # Get conversation history for this model (if provided)
        history = []
        if request.conversation_history and model_id in request.conversation_history:
            history = request.conversation_history[model_id]

        task = _generate_for_model(
            model_id,
            request.prompt,
            request.temperature,
            request.max_tokens,
            request.top_p,
            history,
            override_keys.get(model_id),
            system_prompt,
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
async def chat_single(
    model_id: str,
    request: SingleChatRequest,
    _: None = Depends(require_api_token),
    __: None = Depends(enforce_rate_limit),
) -> ModelResponse:
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
        request.max_tokens,
        request.top_p
    )

    return response


async def _generate_for_model(
    model_id: str,
    prompt: str,
    temperature: float,
    max_tokens: int,
    top_p: Optional[float] = None,
    conversation_history: List = None,
    api_key_override: Optional[str] = None,
    system_prompt: Optional[str] = None,
) -> ModelResponse:
    """
    Generate a response for a specific model.

    Args:
        model_id: The model ID
        prompt: The prompt to send
        temperature: Temperature for generation
        max_tokens: Maximum tokens to generate
        top_p: Nucleus sampling parameter (optional)
        conversation_history: Optional list of previous messages

    Returns:
        ModelResponse with the generated response or error
    """
    if conversation_history is None:
        conversation_history = []

    try:
        if model_id == "gemini":
            return await gemini_service.generate(
                prompt,
                temperature,
                max_tokens,
                top_p,
                conversation_history,
                api_key_override=api_key_override,
                system_prompt=system_prompt,
            )

        elif model_id in ["llama-70b", "llama-8b", "mixtral"]:
            return await groq_service.generate(
                model_id,
                prompt,
                temperature,
                max_tokens,
                top_p,
                conversation_history,
                api_key_override=api_key_override,
                system_prompt=system_prompt,
            )

        elif model_id == "deepseek":
            return await deepseek_service.generate(
                prompt,
                temperature,
                max_tokens,
                top_p,
                conversation_history,
                api_key_override=api_key_override,
                system_prompt=system_prompt,
            )

        elif model_id.startswith("cerebras-"):
            return await cerebras_service.generate(
                model_id,
                config.MODELS[model_id]["model_name"],
                prompt,
                temperature,
                max_tokens,
                top_p,
                conversation_history,
                system_prompt=system_prompt,
            )

        else:
            # This should never happen due to validation, but just in case
            return ModelResponse(
                model=model_id,
                response="",
                tokens=None,
                latency_ms=0,
                error=f"Unknown model: {model_id}",
                error_code=ErrorCode.INVALID_MODEL.value
            )

    except Exception as e:
        # Catch any unexpected errors
        return ModelResponse(
            model=model_id,
            response="",
            tokens=None,
            latency_ms=0,
            error=f"Unexpected error: {str(e)}",
            error_code=ErrorCode.INTERNAL_ERROR.value
        )


def _compose_system_prompt(
    *,
    guide: Optional[str],
    search_context: Optional[SearchContext],
) -> Optional[str]:
    """
    Merge optional guidance and search context into a single system prompt string.

    The resulting prompt encourages complementary perspectives and provides the
    assistant with structured context (and citation hints) when available.
    """
    sections: List[str] = []

    if guide:
        cleaned = guide.strip()
        if cleaned:
            sections.append("Conversation Guide:\n" + cleaned)

    if search_context and search_context.results:
        query = (search_context.query or "").strip()
        summary_lines: List[str] = []
        for idx, result in enumerate(search_context.results, start=1):
            title = result.title.strip()
            snippet = result.snippet.strip()
            url = result.url.strip()
            summary_lines.append(
                f"[S{idx}] {title}\n"
                f"{snippet}\n"
                f"Source: {url}"
            )

        if summary_lines:
            search_header = f"Web Search Findings for \"{query}\":\n" if query else "Web Search Findings:\n"
            sections.append(
                search_header
                + "\n\n".join(summary_lines)
                + "\n\nWhen referencing these sources, cite them inline as [S1], [S2], etc."
            )

    if not sections:
        return None

    header = (
        "You are contributing one perspective within CORO, an app that gathers diverse AI viewpoints. "
        "Offer thoughtful, well-reasoned answers that complement other assistants, and respect the guidance and context below."
    )

    return header + "\n\n" + "\n\n".join(sections)
