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

    # Security / CORS Configuration
    CORS_ALLOWED_ORIGINS: str = os.getenv("CORS_ALLOWED_ORIGINS", "*")
    CORS_ALLOW_CREDENTIALS: bool = os.getenv("CORS_ALLOW_CREDENTIALS", "true").lower() == "true"
    CORO_API_TOKEN: Optional[str] = os.getenv("CORO_API_TOKEN")
    REDIS_URL: Optional[str] = os.getenv("REDIS_URL")

    # Rate limiting (requests per window seconds)
    RATE_LIMITS = {
        "anonymous": {
            "limit": int(os.getenv("RATE_LIMIT_ANONYMOUS_LIMIT", "30")),
            "window": int(os.getenv("RATE_LIMIT_ANONYMOUS_WINDOW", "60")),
        },
        "authenticated": {
            "limit": int(os.getenv("RATE_LIMIT_AUTH_LIMIT", "60")),
            "window": int(os.getenv("RATE_LIMIT_AUTH_WINDOW", "60")),
        },
        "premium": {
            "limit": int(os.getenv("RATE_LIMIT_PREMIUM_LIMIT", "180")),
            "window": int(os.getenv("RATE_LIMIT_PREMIUM_WINDOW", "60")),
        },
    }
    PREMIUM_SESSION_TTL: int = int(os.getenv("PREMIUM_SESSION_TTL", "86400"))  # 24 hours

    # Apple Sign-In
    APPLE_CLIENT_ID: Optional[str] = os.getenv("APPLE_CLIENT_ID")
    APPLE_SKIP_VERIFICATION: bool = os.getenv("APPLE_SKIP_VERIFICATION", "false").lower() == "true"

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

    @classmethod
    def get_allowed_origins(cls) -> list[str]:
        """Return parsed list of allowed origins for CORS configuration."""
        origins = cls.CORS_ALLOWED_ORIGINS
        if not origins or origins == "*":
            return ["*"]

        return [
            origin.strip()
            for origin in origins.split(",")
            if origin.strip()
        ]

    @classmethod
    def should_allow_credentials(cls, origins: list[str]) -> bool:
        """
        Decide whether credentials should be allowed for CORS.

        FastAPI disallows credentials when using a wildcard origin, so we only enable
        them when a concrete origin list is configured.
        """
        if origins == ["*"]:
            return False
        return cls.CORS_ALLOW_CREDENTIALS


# Create config instance
config = Config()
