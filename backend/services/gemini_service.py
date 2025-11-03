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
        max_tokens: int = 512,
        conversation_history: list = None
    ) -> ModelResponse:
        """
        Generate a response using Gemini.

        Args:
            prompt: The input prompt
            temperature: Temperature for generation (0.0-1.0)
            max_tokens: Maximum tokens to generate
            conversation_history: Optional list of previous messages

        Returns:
            ModelResponse with the generated text or error
        """
        start_time = time.time()

        try:
            # Build full prompt from conversation history
            full_prompt = ""
            if conversation_history:
                for msg in conversation_history:
                    role_label = "User" if msg.role == "user" else "Assistant"
                    full_prompt += f"{role_label}: {msg.content}\n\n"

            # Add current prompt
            full_prompt += f"User: {prompt}\n\nAssistant:"

            # Configure generation parameters
            generation_config = genai.GenerationConfig(
                temperature=temperature,
                max_output_tokens=max_tokens,
            )

            # Configure safety settings to be more permissive
            safety_settings = [
                {
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE",
                },
                {
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE",
                },
                {
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE",
                },
                {
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE",
                },
            ]

            # Create model instance
            model = genai.GenerativeModel(
                model_name=self.model_name,
                generation_config=generation_config,
                safety_settings=safety_settings,
            )

            # Generate response
            response = model.generate_content(full_prompt if conversation_history else prompt)

            # Calculate latency
            latency_ms = int((time.time() - start_time) * 1000)

            # Check if response has valid content
            if not response.candidates:
                raise ValueError("No response candidates returned")

            candidate = response.candidates[0]

            # Map finish_reason to human-readable messages
            finish_reason_map = {
                0: "UNSPECIFIED",
                1: "STOP",
                2: "MAX_TOKENS",
                3: "SAFETY",
                4: "RECITATION",
                5: "OTHER"
            }

            finish_reason = candidate.finish_reason
            finish_reason_name = finish_reason_map.get(finish_reason, f"UNKNOWN({finish_reason})")

            # Check for completely blocked content
            if not candidate.content.parts:
                if finish_reason == 3:  # SAFETY
                    raise ValueError("Response blocked by Gemini safety filters. Try rephrasing your prompt.")
                elif finish_reason == 4:  # RECITATION
                    raise ValueError("Response blocked due to potential copyright content.")
                else:
                    raise ValueError(f"No content generated. Reason: {finish_reason_name}")

            # Extract text and token count
            text = response.text

            # Add warning if response was truncated due to max tokens
            if finish_reason == 2:  # MAX_TOKENS
                text += "\n\n[Note: Response truncated due to token limit]"

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
