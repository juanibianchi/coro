"""Configuration management for CORO backend."""

import os
from typing import Optional
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """Application configuration loaded from environment variables."""

    # API Keys
    GEMINI_API_KEY: Optional[str] = os.getenv("GEMINI_API_KEY")
    GROQ_API_KEY: Optional[str] = os.getenv("GROQ_API_KEY")
    DEEPSEEK_API_KEY: Optional[str] = os.getenv("DEEPSEEK_API_KEY")

    # API Configuration
    DEEPSEEK_API_URL: str = "https://api.deepseek.com/v1/chat/completions"

    # Model Configuration
    MODELS = {
        "gemini": {
            "id": "gemini",
            "name": "Gemini 2.5 Flash",
            "provider": "Google",
            "cost": "free",
            "model_name": "gemini-2.5-flash"
        },
        "llama-70b": {
            "id": "llama-70b",
            "name": "Llama 3.3 70B",
            "provider": "Groq",
            "cost": "free",
            "model_name": "llama-3.3-70b-versatile"
        },
        "llama-8b": {
            "id": "llama-8b",
            "name": "Llama 3.1 8B",
            "provider": "Groq",
            "cost": "free",
            "model_name": "llama-3.1-8b-instant"
        },
        "mixtral": {
            "id": "mixtral",
            "name": "Llama 4 Maverick 17B (MoE)",
            "provider": "Groq",
            "cost": "free",
            "model_name": "meta-llama/llama-4-maverick-17b-128e-instruct"
        },
        "deepseek": {
            "id": "deepseek",
            "name": "DeepSeek V2.5",
            "provider": "DeepSeek",
            "cost": "~$0.14/1M tokens",
            "model_name": "deepseek-chat"
        }
    }

    @classmethod
    def validate_keys(cls) -> None:
        """Validate that required API keys are present."""
        missing_keys = []

        if not cls.GEMINI_API_KEY:
            missing_keys.append("GEMINI_API_KEY")
        if not cls.GROQ_API_KEY:
            missing_keys.append("GROQ_API_KEY")
        if not cls.DEEPSEEK_API_KEY:
            missing_keys.append("DEEPSEEK_API_KEY")

        if missing_keys:
            raise ValueError(
                f"Missing required API keys: {', '.join(missing_keys)}. "
                f"Please check your .env file."
            )

    @classmethod
    def get_api_keys_status(cls) -> dict:
        """Get status of all API keys (configured or missing).

        Returns:
            Dictionary with key names and their status (True/False)
        """
        return {
            "GEMINI_API_KEY": bool(cls.GEMINI_API_KEY),
            "GROQ_API_KEY": bool(cls.GROQ_API_KEY),
            "DEEPSEEK_API_KEY": bool(cls.DEEPSEEK_API_KEY)
        }


# Create config instance
config = Config()
