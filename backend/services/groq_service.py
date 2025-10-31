"""Groq API service client for Llama and Mixtral models."""

import time
from typing import Optional
from groq import Groq
from backend.config import config
from backend.models.schemas import ModelResponse


class GroqService:
    """Service for interacting with Groq API (Llama and Mixtral models)."""

    def __init__(self):
        """Initialize Groq service with API key."""
        self.client = None
        if config.GROQ_API_KEY:
            self.client = Groq(api_key=config.GROQ_API_KEY)

    async def generate(
        self,
        model_id: str,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 512
    ) -> ModelResponse:
        """
        Generate a response using a Groq model.

        Args:
            model_id: The model ID (llama-70b, llama-8b, or mixtral)
            prompt: The input prompt
            temperature: Temperature for generation (0.0-1.0)
            max_tokens: Maximum tokens to generate

        Returns:
            ModelResponse with the generated text or error
        """
        start_time = time.time()

        try:
            if not self.client:
                raise ValueError("Groq API key not configured")

            # Get the actual model name from config
            if model_id not in config.MODELS:
                raise ValueError(f"Unknown model ID: {model_id}")

            model_name = config.MODELS[model_id]["model_name"]

            # Create chat completion
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {
                        "role": "user",
                        "content": prompt,
                    }
                ],
                model=model_name,
                temperature=temperature,
                max_tokens=max_tokens,
            )

            # Calculate latency
            latency_ms = int((time.time() - start_time) * 1000)

            # Extract response
            text = chat_completion.choices[0].message.content or ""

            # Get token usage if available
            tokens = None
            if hasattr(chat_completion, 'usage') and chat_completion.usage:
                tokens = chat_completion.usage.completion_tokens

            return ModelResponse(
                model=model_id,
                response=text,
                tokens=tokens,
                latency_ms=latency_ms,
                error=None
            )

        except Exception as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = str(e)

            return ModelResponse(
                model=model_id,
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg
            )
