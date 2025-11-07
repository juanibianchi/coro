"""DeepSeek API service client."""

import time
from typing import Optional
import httpx
from backend.config import config
from backend.models.schemas import ModelResponse
from backend.utils.performance import get_http_client, with_retry
from backend.models.error_codes import ErrorCode, categorize_error


class DeepSeekService:
    """Service for interacting with DeepSeek API via HTTP."""

    def __init__(self):
        """Initialize DeepSeek service."""
        self.api_url = config.DEEPSEEK_API_URL
        self.default_api_key = config.DEEPSEEK_API_KEY
        self.model_name = config.MODELS["deepseek"]["model_name"]

    @with_retry(max_attempts=3, min_wait=1.0, max_wait=10.0)
    async def _make_request(
        self,
        payload: dict,
        headers: dict
    ) -> dict:
        """
        Make HTTP request to DeepSeek API with retry logic.

        Args:
            payload: Request payload
            headers: Request headers

        Returns:
            Response data dictionary

        Raises:
            httpx.HTTPStatusError: On HTTP errors
            httpx.HTTPError: On connection/timeout errors
        """
        client = get_http_client()
        response = await client.post(
            self.api_url,
            json=payload,
            headers=headers
        )
        response.raise_for_status()
        return response.json()

    async def generate(
        self,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 512,
        top_p: Optional[float] = None,
        conversation_history: list = None,
        api_key_override: Optional[str] = None,
        system_prompt: Optional[str] = None
    ) -> ModelResponse:
        """
        Generate a response using DeepSeek API with connection pooling and retry logic.

        Args:
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
            api_key = api_key_override or self.default_api_key
            if not api_key:
                raise ValueError("DeepSeek API key not configured")

            # Build messages array from conversation history
            messages = []
            if system_prompt:
                messages.append({
                    "role": "system",
                    "content": system_prompt
                })
            if conversation_history:
                for msg in conversation_history:
                    messages.append({
                        "role": msg.role,
                        "content": msg.content
                    })

            # Add current prompt
            messages.append({
                "role": "user",
                "content": prompt
            })

            # Prepare request payload
            payload = {
                "model": self.model_name,
                "messages": messages,
                "temperature": temperature,
                "max_tokens": max_tokens
            }

            # Add top_p if provided
            if top_p is not None:
                payload["top_p"] = top_p

            # Prepare headers
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }

            # Make request with retry logic and connection pooling
            data = await self._make_request(payload, headers)

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
                error=None,
                error_code=None
            )

        except httpx.HTTPStatusError as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = f"HTTP {e.response.status_code}: {e.response.text}"

            # Categorize based on HTTP status code
            if e.response.status_code == 401:
                error_code = ErrorCode.AUTHENTICATION_FAILED
            elif e.response.status_code == 429:
                error_code = ErrorCode.RATE_LIMITED
            elif e.response.status_code in [502, 503, 504]:
                error_code = ErrorCode.SERVICE_UNAVAILABLE
            else:
                error_code = categorize_error(e)

            return ModelResponse(
                model="deepseek",
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg,
                error_code=error_code.value
            )

        except Exception as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = str(e)
            error_code = categorize_error(e)

            return ModelResponse(
                model="deepseek",
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg,
                error_code=error_code.value
            )
