"""Google Gemini API service client."""

import time
from typing import Optional, Tuple
import google.generativeai as genai
from backend.config import config
from backend.models.schemas import ModelResponse


class GeminiService:
    """Service for interacting with Google Gemini API."""

    def __init__(self):
        """Initialize Gemini service with API key."""
        if config.GEMINI_API_KEY:
            genai.configure(api_key=config.GEMINI_API_KEY)
        self.model_name = config.MODELS["gemini"]["model_name"]

    async def generate(
        self,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 512
    ) -> ModelResponse:
        """
        Generate a response using Gemini.

        Args:
            prompt: The input prompt
            temperature: Temperature for generation (0.0-1.0)
            max_tokens: Maximum tokens to generate

        Returns:
            ModelResponse with the generated text or error
        """
        start_time = time.time()

        try:
            # Configure generation parameters
            generation_config = genai.GenerationConfig(
                temperature=temperature,
                max_output_tokens=max_tokens,
            )

            # Create model instance
            model = genai.GenerativeModel(
                model_name=self.model_name,
                generation_config=generation_config,
            )

            # Generate response
            response = model.generate_content(prompt)

            # Calculate latency
            latency_ms = int((time.time() - start_time) * 1000)

            # Check if response has valid content
            if not response.candidates:
                raise ValueError("No response candidates returned")

            if not response.candidates[0].content.parts:
                finish_reason = response.candidates[0].finish_reason
                raise ValueError(f"Response blocked or empty. Finish reason: {finish_reason}")

            # Extract text and token count
            text = response.text
            # Gemini doesn't provide token count in response, so we approximate
            tokens = self._estimate_tokens(text)

            return ModelResponse(
                model="gemini",
                response=text,
                tokens=tokens,
                latency_ms=latency_ms,
                error=None
            )

        except Exception as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = str(e)

            return ModelResponse(
                model="gemini",
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg
            )

    @staticmethod
    def _estimate_tokens(text: str) -> int:
        """
        Estimate token count (rough approximation: 1 token ≈ 4 characters).

        Args:
            text: The text to estimate tokens for

        Returns:
            Estimated token count
        """
        return len(text) // 4
