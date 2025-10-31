"""Integration tests for API endpoints."""

import pytest
from fastapi.testclient import TestClient


@pytest.mark.integration
def test_health_endpoint(client):
    """Test the health check endpoint."""
    response = client.get("/health")

    assert response.status_code == 200
    data = response.json()

    assert "status" in data
    assert data["status"] == "ok"
    assert "timestamp" in data


@pytest.mark.integration
def test_models_endpoint(client):
    """Test the models list endpoint."""
    response = client.get("/models")

    assert response.status_code == 200
    data = response.json()

    assert "models" in data
    assert isinstance(data["models"], list)
    assert len(data["models"]) == 5  # We have 5 models total

    # Check model structure
    for model in data["models"]:
        assert "id" in model
        assert "name" in model
        assert "provider" in model
        assert "cost" in model


@pytest.mark.integration
def test_root_endpoint(client):
    """Test the root endpoint."""
    response = client.get("/")

    assert response.status_code == 200
    data = response.json()

    assert "name" in data
    assert "version" in data
    assert "docs" in data
    assert data["name"] == "CORO API"


@pytest.mark.integration
def test_chat_endpoint_validation_missing_prompt(client):
    """Test chat endpoint with missing prompt."""
    response = client.post("/chat", json={
        "models": ["llama-8b"],
        "temperature": 0.7,
        "max_tokens": 100
    })

    assert response.status_code == 422  # Validation error


@pytest.mark.integration
def test_chat_endpoint_validation_missing_models(client):
    """Test chat endpoint with missing models."""
    response = client.post("/chat", json={
        "prompt": "Test",
        "temperature": 0.7,
        "max_tokens": 100
    })

    assert response.status_code == 422  # Validation error


@pytest.mark.integration
def test_chat_endpoint_validation_invalid_model(client):
    """Test chat endpoint with invalid model ID."""
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["invalid-model"],
        "temperature": 0.7,
        "max_tokens": 100
    })

    assert response.status_code == 400
    data = response.json()
    assert "detail" in data
    assert "Invalid model IDs" in data["detail"]


@pytest.mark.integration
def test_chat_endpoint_validation_temperature_range(client):
    """Test chat endpoint with out of range temperature."""
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["llama-8b"],
        "temperature": 1.5,  # Out of range
        "max_tokens": 100
    })

    assert response.status_code == 422  # Validation error


@pytest.mark.integration
def test_chat_endpoint_validation_negative_max_tokens(client):
    """Test chat endpoint with negative max_tokens."""
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["llama-8b"],
        "temperature": 0.7,
        "max_tokens": -10  # Invalid
    })

    assert response.status_code == 422  # Validation error


@pytest.mark.integration
def test_single_chat_endpoint_validation_invalid_model(client):
    """Test single chat endpoint with invalid model."""
    response = client.post("/chat/invalid-model", json={
        "prompt": "Test",
        "temperature": 0.7,
        "max_tokens": 100
    })

    assert response.status_code == 400
    data = response.json()
    assert "detail" in data
    assert "Invalid model ID" in data["detail"]


@pytest.mark.integration
def test_chat_response_structure(client, sample_chat_request):
    """Test that chat response has correct structure."""
    response = client.post("/chat", json=sample_chat_request)

    # May succeed or fail depending on API keys, but should have correct structure
    if response.status_code == 200:
        data = response.json()

        assert "responses" in data
        assert "total_latency_ms" in data
        assert isinstance(data["responses"], list)
        assert isinstance(data["total_latency_ms"], int)

        # Check each response has correct structure
        for model_response in data["responses"]:
            assert "model" in model_response
            assert "response" in model_response
            assert "latency_ms" in model_response
            assert "error" in model_response or model_response["error"] is None

            # Either has a response or an error, not both
            if model_response["error"]:
                assert isinstance(model_response["error"], str)


@pytest.mark.integration
def test_single_chat_response_structure(client, sample_single_chat_request):
    """Test that single chat response has correct structure."""
    response = client.post("/chat/llama-8b", json=sample_single_chat_request)

    # May succeed or fail depending on API keys, but should have correct structure
    if response.status_code == 200:
        data = response.json()

        assert "model" in data
        assert "response" in data
        assert "latency_ms" in data
        assert "error" in data or data["error"] is None
        assert data["model"] == "llama-8b"


@pytest.mark.integration
def test_chat_endpoint_empty_models_list(client):
    """Test chat endpoint with empty models list."""
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": [],
        "temperature": 0.7,
        "max_tokens": 100
    })

    assert response.status_code == 422  # Validation error


@pytest.mark.integration
def test_openapi_docs(client):
    """Test that OpenAPI documentation is accessible."""
    response = client.get("/docs")
    assert response.status_code == 200


@pytest.mark.integration
def test_redoc_docs(client):
    """Test that ReDoc documentation is accessible."""
    response = client.get("/redoc")
    assert response.status_code == 200
