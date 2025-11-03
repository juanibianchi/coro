"""Tests for Gemini finish_reason handling."""

import pytest
from unittest.mock import Mock, patch, AsyncMock
from backend.services.gemini_service import GeminiService
from backend.models.schemas import ModelResponse


@pytest.mark.asyncio
async def test_gemini_handles_max_tokens_finish_reason():
    """Test that MAX_TOKENS finish_reason returns partial content with note."""
    service = GeminiService()

    # Mock the Gemini API response
    mock_response = Mock()
    mock_response.candidates = [Mock()]
    mock_response.candidates[0].finish_reason = 2  # MAX_TOKENS
    mock_response.candidates[0].content.parts = [Mock(text="Partial response")]
    mock_response.text = "Partial response"

    with patch('google.generativeai.GenerativeModel') as mock_model_class:
        mock_model = Mock()
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model

        result = await service.generate("Test prompt", 0.7, 512)

        assert result.error is None
        assert "Partial response" in result.response
        assert "[Note: Response truncated due to token limit]" in result.response
        assert result.model == "gemini"


@pytest.mark.asyncio
async def test_gemini_handles_safety_finish_reason():
    """Test that SAFETY finish_reason returns appropriate error message."""
    service = GeminiService()

    # Mock the Gemini API response
    mock_response = Mock()
    mock_response.candidates = [Mock()]
    mock_response.candidates[0].finish_reason = 3  # SAFETY
    mock_response.candidates[0].content.parts = []  # No content due to safety block

    with patch('google.generativeai.GenerativeModel') as mock_model_class:
        mock_model = Mock()
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model

        result = await service.generate("Test prompt", 0.7, 512)

        assert result.error is not None
        assert "safety filters" in result.error.lower()
        assert result.response == ""


@pytest.mark.asyncio
async def test_gemini_handles_recitation_finish_reason():
    """Test that RECITATION finish_reason returns appropriate error message."""
    service = GeminiService()

    # Mock the Gemini API response
    mock_response = Mock()
    mock_response.candidates = [Mock()]
    mock_response.candidates[0].finish_reason = 4  # RECITATION
    mock_response.candidates[0].content.parts = []

    with patch('google.generativeai.GenerativeModel') as mock_model_class:
        mock_model = Mock()
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model

        result = await service.generate("Test prompt", 0.7, 512)

        assert result.error is not None
        assert "copyright" in result.error.lower()
        assert result.response == ""


@pytest.mark.asyncio
async def test_gemini_handles_stop_finish_reason():
    """Test that STOP finish_reason (normal completion) works correctly."""
    service = GeminiService()

    # Mock the Gemini API response
    mock_response = Mock()
    mock_response.candidates = [Mock()]
    mock_response.candidates[0].finish_reason = 1  # STOP (normal)
    mock_response.candidates[0].content.parts = [Mock(text="Complete response")]
    mock_response.text = "Complete response"

    with patch('google.generativeai.GenerativeModel') as mock_model_class:
        mock_model = Mock()
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model

        result = await service.generate("Test prompt", 0.7, 512)

        assert result.error is None
        assert result.response == "Complete response"
        assert "[Note: Response truncated" not in result.response


@pytest.mark.asyncio
async def test_gemini_handles_unknown_finish_reason():
    """Test that unknown finish_reason codes are handled gracefully."""
    service = GeminiService()

    # Mock the Gemini API response
    mock_response = Mock()
    mock_response.candidates = [Mock()]
    mock_response.candidates[0].finish_reason = 99  # Unknown code
    mock_response.candidates[0].content.parts = []

    with patch('google.generativeai.GenerativeModel') as mock_model_class:
        mock_model = Mock()
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model

        result = await service.generate("Test prompt", 0.7, 512)

        assert result.error is not None
        assert "UNKNOWN" in result.error


@pytest.mark.asyncio
async def test_gemini_with_conversation_history():
    """Test that conversation history is properly formatted in Gemini requests."""
    service = GeminiService()

    # Mock the Gemini API response
    mock_response = Mock()
    mock_response.candidates = [Mock()]
    mock_response.candidates[0].finish_reason = 1
    mock_response.candidates[0].content.parts = [Mock(text="Response")]
    mock_response.text = "Response"

    conversation_history = [
        Mock(role="user", content="Previous question"),
        Mock(role="assistant", content="Previous answer")
    ]

    with patch('google.generativeai.GenerativeModel') as mock_model_class:
        mock_model = Mock()
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model

        result = await service.generate("New question", 0.7, 512, conversation_history)

        # Verify the model was called with formatted history
        call_args = mock_model.generate_content.call_args[0][0]
        assert "User: Previous question" in call_args
        assert "Assistant: Previous answer" in call_args
        assert "User: New question" in call_args
        assert result.error is None
