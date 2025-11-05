"""Groq API service client for Llama and Mixtral models."""

import time
from typing import Optional
from groq import Groq
from backend.config import config
from backend.models.schemas import ModelResponse
from backend.models.error_codes import ErrorCode, categorize_error


class GroqService:
    """Service for interacting with Groq API (Llama and Mixtral models)."""

    def __init__(self):
        """Initialize Groq service with API key."""
        self.default_api_key = config.GROQ_API_KEY
        self.client = Groq(api_key=self.default_api_key) if self.default_api_key else None

    async def generate(
        self,
        model_id: str,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 512,
        top_p: Optional[float] = None,
        conversation_history: list = None,
        api_key_override: Optional[str] = None
    ) -> ModelResponse:
        """
        Generate a response using a Groq model.

        Args:
            model_id: The model ID (llama-70b, llama-8b, or mixtral)
            prompt: The input prompt
            temperature: Temperature for generation (0.0-2.0)
            max_tokens: Maximum tokens to generate (1-32000)
            top_p: Nucleus sampling parameter (0.0-1.0, optional)
            conversation_history: Optional list of previous messages

        Returns:
            ModelResponse with the generated text or error
        """
        start_time = time.time()

        try:
            client = self.client
            if api_key_override:
                client = Groq(api_key=api_key_override)

            if not client:
                raise ValueError("Groq API key not configured")

            # Get the actual model name from config
            if model_id not in config.MODELS:
                raise ValueError(f"Unknown model ID: {model_id}")

            model_name = config.MODELS[model_id]["model_name"]

            # Build messages array from conversation history
            messages = []
            if conversation_history:
                for msg in conversation_history:
                    messages.append({
                        "role": msg.role,
                        "content": msg.content
                    })

            # Add current prompt
            messages.append({
                "role": "user",
                "content": prompt,
            })

            # Create chat completion with parameters
            completion_params = {
                "messages": messages,
                "model": model_name,
                "temperature": temperature,
                "max_tokens": max_tokens,
            }

            # Add top_p if provided
            if top_p is not None:
                completion_params["top_p"] = top_p

            chat_completion = client.chat.completions.create(**completion_params)

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
                error=None,
                error_code=None
            )

        except Exception as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = str(e)
            error_code = categorize_error(e)

            return ModelResponse(
                model=model_id,
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg,
                error_code=error_code.value
            )
