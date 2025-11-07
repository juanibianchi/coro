"""Cerebras inference client."""

from __future__ import annotations

import time
from typing import List, Optional

import httpx

from backend.config import config
from backend.models.schemas import ModelResponse
from backend.models.error_codes import ErrorCode, categorize_error


class CerebrasService:
    """Minimal client for Cerebras chat completions."""

    def __init__(self) -> None:
        self.api_url = config.CEREBRAS_API_URL
        self.api_key = config.CEREBRAS_API_KEY

    async def generate(
        self,
        return_model_id: str,
        provider_model_id: str,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 512,
        top_p: Optional[float] = None,
        conversation_history: List | None = None,
        system_prompt: Optional[str] = None,
    ) -> ModelResponse:
        start_time = time.time()

        if not self.api_key:
            return ModelResponse(
                model=return_model_id,
                response="",
                tokens=None,
                latency_ms=int((time.time() - start_time) * 1000),
                error="Cerebras API key not configured",
                error_code=ErrorCode.AUTHENTICATION_FAILED.value,
            )

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        if conversation_history:
            messages.extend({"role": msg.role, "content": msg.content} for msg in conversation_history)
        messages.append({"role": "user", "content": prompt})

        payload: dict[str, object] = {
            "model": provider_model_id,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if top_p is not None:
            payload["top_p"] = top_p

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(self.api_url, json=payload, headers=headers)
                response.raise_for_status()
                data = response.json()
        except Exception as exc:  # noqa: BLE001
            latency_ms = int((time.time() - start_time) * 1000)
            err_code = categorize_error(exc)
            return ModelResponse(
                model=return_model_id,
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=str(exc),
                error_code=err_code.value,
            )

        latency_ms = int((time.time() - start_time) * 1000)
        choices = data.get("choices", [])
        text = choices[0]["message"]["content"] if choices else ""
        usage = data.get("usage", {})
        tokens = usage.get("completion_tokens")

        return ModelResponse(
            model=return_model_id,
            response=text,
            tokens=tokens,
            latency_ms=latency_ms,
            error=None,
            error_code=None,
        )


cerebras_service = CerebrasService()
