"""Pytest configuration and fixtures."""

import os
import sys
import pytest
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir.parent))

from fastapi.testclient import TestClient
from backend.main import app


@pytest.fixture
def client():
    """FastAPI test client fixture."""
    return TestClient(app)


@pytest.fixture
def mock_env_vars(monkeypatch):
    """Mock environment variables for testing."""
    monkeypatch.setenv("GEMINI_API_KEY", "test_gemini_key")
    monkeypatch.setenv("GROQ_API_KEY", "test_groq_key")
    monkeypatch.setenv("DEEPSEEK_API_KEY", "test_deepseek_key")


@pytest.fixture
def sample_chat_request():
    """Sample chat request payload."""
    return {
        "prompt": "What is 2+2?",
        "models": ["llama-8b"],
        "temperature": 0.7,
        "max_tokens": 100
    }


@pytest.fixture
def sample_single_chat_request():
    """Sample single model chat request payload."""
    return {
        "prompt": "What is 2+2?",
        "temperature": 0.7,
        "max_tokens": 100
    }


@pytest.fixture
def all_models():
    """List of all available model IDs."""
    return ["gemini", "llama-70b", "llama-8b", "mixtral"]
