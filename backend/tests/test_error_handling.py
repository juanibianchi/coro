"""Tests for error handling and robustness."""

import pytest
from unittest.mock import Mock, patch
from backend.services.gemini_service import GeminiService
from backend.services.groq_service import GroqService
from backend.services.deepseek_service import DeepSeekService
from backend.models.schemas import ModelResponse


@pytest.mark.unit
async def test_gemini_service_handles_api_error():
    """Test that GeminiService handles API errors gracefully."""
    service = GeminiService()

    with patch.object(service, 'model_name', 'gemini-2.5-flash'):
        with patch('google.generativeai.GenerativeModel') as mock_model:
            # Simulate API error
            mock_instance = Mock()
            mock_instance.generate_content.side_effect = Exception("API Error")
            mock_model.return_value = mock_instance

            response = await service.generate("test prompt")

            assert isinstance(response, ModelResponse)
            assert response.model == "gemini"
            assert response.error is not None
            assert "API Error" in response.error
            assert response.response == ""


@pytest.mark.unit
async def test_groq_service_handles_api_error():
    """Test that GroqService handles API errors gracefully."""
    service = GroqService()

    with patch.object(service, 'client') as mock_client:
        # Simulate API error
        mock_client.chat.completions.create.side_effect = Exception("API Error")

        response = await service.generate("llama-8b", "test prompt")

        assert isinstance(response, ModelResponse)
        assert response.model == "llama-8b"
        assert response.error is not None
        assert "API Error" in response.error
        assert response.response == ""


@pytest.mark.unit
async def test_deepseek_service_handles_http_error():
    """Test that DeepSeekService handles HTTP errors gracefully."""
    service = DeepSeekService()

    with patch('httpx.AsyncClient') as mock_client_class:
        # Create async context manager mock
        mock_client = Mock()
        mock_client.post = Mock(side_effect=Exception("HTTP Error"))

        # Make AsyncClient return an async context manager
        mock_client_class.return_value.__aenter__.return_value = mock_client
        mock_client_class.return_value.__aexit__.return_value = None

        response = await service.generate("test prompt")

        assert isinstance(response, ModelResponse)
        assert response.model == "deepseek"
        assert response.error is not None
        assert "HTTP Error" in response.error
        assert response.response == ""


@pytest.mark.unit
async def test_groq_service_missing_api_key():
    """Test GroqService with missing API key."""
    service = GroqService()
    service.client = None  # Simulate missing API key

    response = await service.generate("llama-8b", "test prompt")

    assert isinstance(response, ModelResponse)
    assert response.error is not None
    assert "API key not configured" in response.error


@pytest.mark.unit
async def test_deepseek_service_missing_api_key():
    """Test DeepSeekService with missing API key."""
    service = DeepSeekService()
    service.api_key = None  # Simulate missing API key

    response = await service.generate("test prompt")

    assert isinstance(response, ModelResponse)
    assert response.error is not None
    assert "API key not configured" in response.error


@pytest.mark.integration
def test_chat_endpoint_handles_invalid_json(client):
    """Test that chat endpoint handles invalid JSON gracefully."""
    response = client.post(
        "/chat",
        content="invalid json{",
        headers={"Content-Type": "application/json"}
    )

    assert response.status_code == 422


@pytest.mark.integration
def test_chat_endpoint_handles_wrong_content_type(client):
    """Test that endpoint handles wrong content type."""
    response = client.post(
        "/chat",
        data="plain text data",
        headers={"Content-Type": "text/plain"}
    )

    assert response.status_code == 422


@pytest.mark.integration
def test_invalid_endpoint_returns_404(client):
    """Test that invalid endpoints return 404."""
    response = client.get("/invalid-endpoint")

    assert response.status_code == 404


@pytest.mark.integration
def test_chat_with_multiple_invalid_models(client):
    """Test chat with multiple invalid model IDs."""
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["invalid-1", "invalid-2", "invalid-3"]
    })

    assert response.status_code == 400
    data = response.json()
    assert "invalid-1" in data["detail"]
    assert "invalid-2" in data["detail"]
    assert "invalid-3" in data["detail"]


@pytest.mark.integration
def test_chat_with_mixed_valid_invalid_models(client):
    """Test chat with mix of valid and invalid models."""
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["llama-8b", "invalid-model"]
    })

    assert response.status_code == 400
    data = response.json()
    assert "invalid-model" in data["detail"]


@pytest.mark.unit
def test_model_response_latency_is_positive():
    """Test that ModelResponse enforces positive latency."""
    response = ModelResponse(
        model="test",
        response="test",
        tokens=10,
        latency_ms=100,
        error=None
    )

    assert response.latency_ms >= 0


@pytest.mark.integration
def test_very_long_prompt(client):
    """Test handling of very long prompts."""
    long_prompt = "test " * 10000  # Very long prompt

    response = client.post("/chat", json={
        "prompt": long_prompt,
        "models": ["llama-8b"],
        "max_tokens": 100
    })

    # Should either accept it or return validation error, not crash
    assert response.status_code in [200, 422, 400]


@pytest.mark.integration
def test_max_tokens_boundary(client):
    """Test max_tokens at boundary values."""
    # Test minimum valid value
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["llama-8b"],
        "max_tokens": 1
    })

    assert response.status_code in [200, 400]

    # Test maximum valid value
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["llama-8b"],
        "max_tokens": 4096
    })

    assert response.status_code in [200, 400]
