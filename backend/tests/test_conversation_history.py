"""Tests for conversation history functionality."""

import pytest


def test_chat_with_conversation_history(client):
    """Test that conversation history is passed to models correctly."""
    # First request without history
    request_data = {
        "prompt": "What is 2+2?",
        "models": ["gemini"],
        "temperature": 0.7,
        "max_tokens": 512
    }

    response = client.post("/chat", json=request_data)
    assert response.status_code == 200
    data = response.json()
    assert "responses" in data
    assert len(data["responses"]) == 1

    # Second request with conversation history
    request_with_history = {
        "prompt": "What about 3+3?",
        "models": ["gemini"],
        "temperature": 0.7,
        "max_tokens": 512,
        "conversation_history": {
            "gemini": [
                {"role": "user", "content": "What is 2+2?"},
                {"role": "assistant", "content": "4"}
            ]
        }
    }

    response = client.post("/chat", json=request_with_history)
    assert response.status_code == 200
    data = response.json()
    assert "responses" in data
    assert len(data["responses"]) == 1


def test_chat_with_multiple_model_histories(client):
    """Test conversation history with multiple models."""
    request_data = {
        "prompt": "Continue our conversation",
        "models": ["gemini", "llama-8b"],
        "conversation_history": {
            "gemini": [
                {"role": "user", "content": "Hello"},
                {"role": "assistant", "content": "Hi there!"}
            ],
            "llama-8b": [
                {"role": "user", "content": "Hi"},
                {"role": "assistant", "content": "Hello!"}
            ]
        }
    }

    response = client.post("/chat", json=request_data)
    assert response.status_code == 200
    data = response.json()
    assert len(data["responses"]) == 2


def test_chat_with_empty_conversation_history(client):
    """Test that empty conversation history is handled correctly."""
    request_data = {
        "prompt": "Test prompt",
        "models": ["gemini"],
        "conversation_history": {}
    }

    response = client.post("/chat", json=request_data)
    assert response.status_code == 200
    data = response.json()
    assert "responses" in data


def test_conversation_history_format_validation(client):
    """Test that conversation history has correct format."""
    # Valid format
    valid_request = {
        "prompt": "Test",
        "models": ["gemini"],
        "conversation_history": {
            "gemini": [
                {"role": "user", "content": "test"}
            ]
        }
    }

    response = client.post("/chat", json=valid_request)
    assert response.status_code == 200


def test_long_conversation_history(client):
    """Test handling of long conversation histories."""
    # Create a long history
    long_history = []
    for i in range(20):
        long_history.append({"role": "user", "content": f"Question {i}"})
        long_history.append({"role": "assistant", "content": f"Answer {i}"})

    request_data = {
        "prompt": "Final question",
        "models": ["gemini"],
        "conversation_history": {
            "gemini": long_history
        }
    }

    response = client.post("/chat", json=request_data)
    assert response.status_code == 200
    data = response.json()
    assert "responses" in data
