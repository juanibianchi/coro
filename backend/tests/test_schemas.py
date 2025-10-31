"""Unit tests for Pydantic schemas."""

import pytest
from pydantic import ValidationError
from backend.models.schemas import (
    ChatRequest,
    SingleChatRequest,
    ModelResponse,
    ChatResponse,
    ModelInfo,
    ModelsResponse,
    HealthResponse
)


@pytest.mark.unit
def test_chat_request_valid():
    """Test valid ChatRequest creation."""
    request = ChatRequest(
        prompt="Test prompt",
        models=["gemini", "llama-8b"],
        temperature=0.7,
        max_tokens=512
    )

    assert request.prompt == "Test prompt"
    assert request.models == ["gemini", "llama-8b"]
    assert request.temperature == 0.7
    assert request.max_tokens == 512


@pytest.mark.unit
def test_chat_request_defaults():
    """Test ChatRequest default values."""
    request = ChatRequest(
        prompt="Test",
        models=["gemini"]
    )

    assert request.temperature == 0.7
    assert request.max_tokens == 512


@pytest.mark.unit
def test_chat_request_invalid_temperature():
    """Test ChatRequest with invalid temperature."""
    with pytest.raises(ValidationError):
        ChatRequest(
            prompt="Test",
            models=["gemini"],
            temperature=1.5  # Out of range
        )

    with pytest.raises(ValidationError):
        ChatRequest(
            prompt="Test",
            models=["gemini"],
            temperature=-0.1  # Out of range
        )


@pytest.mark.unit
def test_chat_request_invalid_max_tokens():
    """Test ChatRequest with invalid max_tokens."""
    with pytest.raises(ValidationError):
        ChatRequest(
            prompt="Test",
            models=["gemini"],
            max_tokens=0  # Too low
        )

    with pytest.raises(ValidationError):
        ChatRequest(
            prompt="Test",
            models=["gemini"],
            max_tokens=-10  # Negative
        )


@pytest.mark.unit
def test_chat_request_empty_prompt():
    """Test ChatRequest with empty prompt."""
    with pytest.raises(ValidationError):
        ChatRequest(
            prompt="",
            models=["gemini"]
        )


@pytest.mark.unit
def test_chat_request_empty_models():
    """Test ChatRequest with empty models list."""
    with pytest.raises(ValidationError):
        ChatRequest(
            prompt="Test",
            models=[]
        )


@pytest.mark.unit
def test_single_chat_request_valid():
    """Test valid SingleChatRequest creation."""
    request = SingleChatRequest(
        prompt="Test",
        temperature=0.5,
        max_tokens=256
    )

    assert request.prompt == "Test"
    assert request.temperature == 0.5
    assert request.max_tokens == 256


@pytest.mark.unit
def test_model_response_success():
    """Test ModelResponse for successful response."""
    response = ModelResponse(
        model="gemini",
        response="Test response",
        tokens=10,
        latency_ms=500,
        error=None
    )

    assert response.model == "gemini"
    assert response.response == "Test response"
    assert response.tokens == 10
    assert response.latency_ms == 500
    assert response.error is None


@pytest.mark.unit
def test_model_response_error():
    """Test ModelResponse for error case."""
    response = ModelResponse(
        model="gemini",
        response="",
        tokens=None,
        latency_ms=100,
        error="API error"
    )

    assert response.model == "gemini"
    assert response.response == ""
    assert response.tokens is None
    assert response.latency_ms == 100
    assert response.error == "API error"


@pytest.mark.unit
def test_chat_response_valid():
    """Test valid ChatResponse creation."""
    responses = [
        ModelResponse(
            model="gemini",
            response="Test",
            tokens=5,
            latency_ms=500,
            error=None
        )
    ]

    chat_response = ChatResponse(
        responses=responses,
        total_latency_ms=500
    )

    assert len(chat_response.responses) == 1
    assert chat_response.total_latency_ms == 500


@pytest.mark.unit
def test_model_info_valid():
    """Test valid ModelInfo creation."""
    info = ModelInfo(
        id="gemini",
        name="Gemini 2.5 Flash",
        provider="Google",
        cost="free"
    )

    assert info.id == "gemini"
    assert info.name == "Gemini 2.5 Flash"
    assert info.provider == "Google"
    assert info.cost == "free"


@pytest.mark.unit
def test_models_response_valid():
    """Test valid ModelsResponse creation."""
    models = [
        ModelInfo(id="gemini", name="Gemini", provider="Google", cost="free"),
        ModelInfo(id="llama-8b", name="Llama 8B", provider="Groq", cost="free")
    ]

    response = ModelsResponse(models=models)

    assert len(response.models) == 2


@pytest.mark.unit
def test_health_response_valid():
    """Test valid HealthResponse creation."""
    from datetime import datetime, timezone

    timestamp = datetime.now(timezone.utc).isoformat()
    response = HealthResponse(
        status="ok",
        timestamp=timestamp
    )

    assert response.status == "ok"
    assert response.timestamp == timestamp
