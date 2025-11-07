"""Google Gemini API service client."""

import time
from typing import Optional
import google.generativeai as genai
from backend.config import config
from backend.models.schemas import ModelResponse
from backend.models.error_codes import ErrorCode, categorize_error


class GeminiService:
    """Service for interacting with Google Gemini API."""

    def __init__(self):
        """Initialize Gemini service with API key."""
        self.default_api_key = config.GEMINI_API_KEY
        if self.default_api_key:
            genai.configure(api_key=self.default_api_key)
        self.model_name = config.MODELS["gemini"]["model_name"]

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
        Generate a response using Gemini.

        Args:
            prompt: The input prompt
            temperature: Temperature for generation (0.0-2.0)
            max_tokens: Maximum tokens to generate (1-32000)
            top_p: Nucleus sampling parameter (0.0-1.0, optional)
            conversation_history: Optional list of previous messages
            system_prompt: Optional system-level instructions/context to prepend

        Returns:
            ModelResponse with the generated text or error
        """
        start_time = time.time()

        api_key = api_key_override or self.default_api_key
        if not api_key:
            raise ValueError("Gemini API key not configured")

        # Configure Google client on each call to respect overrides
        genai.configure(api_key=api_key)

        try:
            # Build full prompt with optional system guidance and conversation history
            sections = []

            if system_prompt:
                sections.append(system_prompt.strip())

            full_prompt = ""
            if conversation_history:
                for msg in conversation_history:
                    role_label = "User" if msg.role == "user" else "Assistant"
                    full_prompt += f"{role_label}: {msg.content}\n\n"
                if full_prompt:
                    sections.append(full_prompt.strip())

            prompt_section = f"User: {prompt}\n\nAssistant:"
            sections.append(prompt_section)

            combined_prompt = "\n\n".join(section for section in sections if section)

            # Configure generation parameters
            config_params = {
                "temperature": temperature,
                "max_output_tokens": max_tokens,
            }

            # Add top_p if provided
            if top_p is not None:
                config_params["top_p"] = top_p

            generation_config = genai.GenerationConfig(**config_params)

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
            response = model.generate_content(combined_prompt)

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
                error=None,
                error_code=None
            )

        except Exception as e:
            latency_ms = int((time.time() - start_time) * 1000)
            error_msg = str(e)
            error_code = categorize_error(e)

            # Override error code for specific Gemini issues
            if "safety" in error_msg.lower() or "blocked" in error_msg.lower():
                error_code = ErrorCode.CONTENT_FILTERED
            elif "api key" in error_msg.lower():
                error_code = ErrorCode.AUTHENTICATION_FAILED

            return ModelResponse(
                model="gemini",
                response="",
                tokens=None,
                latency_ms=latency_ms,
                error=error_msg,
                error_code=error_code.value
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
