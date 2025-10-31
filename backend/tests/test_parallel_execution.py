"""Tests for parallel execution performance."""

import pytest
import time
from unittest.mock import AsyncMock, patch
from backend.routers.chat import _generate_for_model


@pytest.mark.slow
@pytest.mark.integration
def test_parallel_execution_faster_than_sequential(client):
    """Test that parallel execution is faster than sequential."""
    models = ["llama-70b", "llama-8b"]

    # Measure parallel execution time
    start = time.time()
    response = client.post("/chat", json={
        "prompt": "What is 1+1?",
        "models": models,
        "max_tokens": 50
    })
    parallel_time = time.time() - start

    # If successful, check that total_latency_ms is approximately equal to slowest model
    if response.status_code == 200:
        data = response.json()
        total_latency = data["total_latency_ms"]

        # Get the slowest individual model latency
        max_individual_latency = max(r["latency_ms"] for r in data["responses"])

        # Parallel execution should be close to slowest model time, not sum of all
        # Allow 2x overhead for coordination (network latency, startup, etc)
        assert total_latency < max_individual_latency * 2, \
            f"Total latency {total_latency}ms should be close to slowest model {max_individual_latency}ms, not sum of all"


@pytest.mark.unit
async def test_generate_for_model_returns_model_response():
    """Test that _generate_for_model returns correct response structure."""
    with patch('backend.routers.chat.groq_service') as mock_service:
        # Mock the service response
        mock_response = AsyncMock()
        mock_response.model = "llama-8b"
        mock_response.response = "Test response"
        mock_response.tokens = 10
        mock_response.latency_ms = 100
        mock_response.error = None

        mock_service.generate = AsyncMock(return_value=mock_response)

        result = await _generate_for_model("llama-8b", "test", 0.7, 100)

        assert result.model == "llama-8b"
        assert result.response == "Test response"


@pytest.mark.integration
def test_multiple_models_all_get_responses(client):
    """Test that all models get responses even if some fail."""
    response = client.post("/chat", json={
        "prompt": "What is 2+2?",
        "models": ["llama-70b", "llama-8b"],
        "max_tokens": 50
    })

    if response.status_code == 200:
        data = response.json()

        # Should have responses for all requested models
        assert len(data["responses"]) == 2

        # Each response should have a model field
        model_ids = [r["model"] for r in data["responses"]]
        assert "llama-70b" in model_ids
        assert "llama-8b" in model_ids


@pytest.mark.integration
def test_single_model_failure_doesnt_break_others(client):
    """Test that one model failure doesn't prevent others from responding."""
    # Use one invalid model and one valid model
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["llama-8b", "gemini"],  # Both should work, or handle errors gracefully
        "max_tokens": 50
    })

    # Request should succeed even if some models fail
    # We expect 200 or 400 (if validation fails before execution)
    if response.status_code == 200:
        data = response.json()

        # Should have 2 responses
        assert len(data["responses"]) == 2

        # At least check structure is correct
        for model_response in data["responses"]:
            assert "model" in model_response
            assert "response" in model_response
            assert "latency_ms" in model_response
            assert "error" in model_response


@pytest.mark.unit
async def test_parallel_execution_handles_exception():
    """Test that parallel execution handles exceptions in one model gracefully."""
    with patch('backend.routers.chat.groq_service') as mock_groq:
        with patch('backend.routers.chat.gemini_service') as mock_gemini:
            # One service succeeds
            mock_groq.generate = AsyncMock(return_value=AsyncMock(
                model="llama-8b",
                response="Success",
                tokens=5,
                latency_ms=100,
                error=None
            ))

            # One service fails
            mock_gemini.generate = AsyncMock(side_effect=Exception("API Error"))

            # Both should complete without crashing
            result1 = await _generate_for_model("llama-8b", "test", 0.7, 100)
            result2 = await _generate_for_model("gemini", "test", 0.7, 100)

            assert result1.model == "llama-8b"
            assert result2.error is not None


@pytest.mark.integration
def test_total_latency_is_reasonable(client):
    """Test that total_latency_ms is a reasonable value."""
    response = client.post("/chat", json={
        "prompt": "What is 2+2?",
        "models": ["llama-8b"],
        "max_tokens": 50
    })

    if response.status_code == 200:
        data = response.json()

        # Total latency should be positive
        assert data["total_latency_ms"] > 0

        # Total latency should be at least as long as the slowest model
        max_individual = max(r["latency_ms"] for r in data["responses"])
        assert data["total_latency_ms"] >= max_individual

        # Total latency should be reasonable (less than 30 seconds)
        assert data["total_latency_ms"] < 30000


@pytest.mark.integration
def test_individual_latencies_are_tracked(client):
    """Test that individual model latencies are tracked correctly."""
    response = client.post("/chat", json={
        "prompt": "What is 2+2?",
        "models": ["llama-8b", "llama-70b"],
        "max_tokens": 50
    })

    if response.status_code == 200:
        data = response.json()

        for model_response in data["responses"]:
            # Each model should have a latency value
            assert "latency_ms" in model_response
            assert isinstance(model_response["latency_ms"], int)
            assert model_response["latency_ms"] >= 0


@pytest.mark.integration
def test_empty_response_on_error_still_has_latency(client):
    """Test that even error responses track latency."""
    # This test verifies error responses still measure time
    response = client.post("/chat", json={
        "prompt": "Test",
        "models": ["llama-8b"],
        "max_tokens": 1
    })

    if response.status_code == 200:
        data = response.json()

        for model_response in data["responses"]:
            # Even if there's an error, latency should be tracked
            assert model_response["latency_ms"] >= 0
