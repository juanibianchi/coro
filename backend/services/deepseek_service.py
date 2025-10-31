"""DeepSeek API service client."""

import time
from typing import Optional
import httpx
from backend.config import config
from backend.models.schemas import ModelResponse


class DeepSeekService:
    """Service for interacting with DeepSeek API via HTTP."""

    def __init__(self):
        """Initialize DeepSeek service."""
        self.api_url = config.DEEPSEEK_API_URL
        self.api_key = config.DEEPSEEK_API_KEY
        self.model_name = config.MODELS["deepseek"]["model_name"]

    async def generate(
        self,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 512
    ) -> ModelResponse:
        """
        Generate a response using DeepSeek API.

        Args:
            prompt: The input prompt
            temperature: Temperature for generation (0.0-1.0)
            max_tokens: Maximum tokens to generate

        Returns:
            ModelResponse with the generated text or error
        """
        start_time = time.time()

        try:
            if not self.api_key:
                raise ValueError("DeepSeek API key not configured")

            # Prepare request payload
            payload = {
                "model": self.model_name,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": temperature,
                "max_tokens": max_tokens
            }

            # Prepare headers
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }

            # Make async HTTP request
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    self.api_url,
                    json=payload,
                    headers=headers
                )
                response.raise_for_status()
                data = response.json()

            # Calculate latency
            latency_ms = int((time.time() - start_time) * 1000)

            # Extract response text
            text = data.get("choices", [{}])[0].get("message", {}).get("content", "")

            # Get token count if available
            tokens = None
            if "usage" in data and "completion_tokens" in data["usage"]:
                tokens = data["usage"]["completion_tokens"]

            return ModelResponse(
                model="deepseek",
                response=text,
                tokens=tokens,
                latency_ms=latency_ms,
                error=None
            )

        except httpx.HTTPStatusError as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = f"HTTP {e.response.status_code}: {e.response.text}"

            return ModelResponse(
                model="deepseek",
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg
            )

        except Exception as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = str(e)

            return ModelResponse(
                model="deepseek",
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg
            )
