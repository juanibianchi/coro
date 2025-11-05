"""Standardized error codes for better error handling and user experience."""

from enum import Enum


class ErrorCode(str, Enum):
    """
    Standardized error codes for API responses.

    These codes help clients provide better user experience by showing
    appropriate messages and actions based on the error type.
    """

    # Authentication & Authorization
    AUTHENTICATION_FAILED = "authentication_failed"
    API_KEY_MISSING = "api_key_missing"
    API_KEY_INVALID = "api_key_invalid"
    UNAUTHORIZED = "unauthorized"

    # Rate Limiting & Quotas
    RATE_LIMITED = "rate_limited"
    QUOTA_EXCEEDED = "quota_exceeded"

    # Request Issues
    INVALID_REQUEST = "invalid_request"
    INVALID_MODEL = "invalid_model"
    INVALID_PARAMETERS = "invalid_parameters"

    # Model/Service Issues
    MODEL_OVERLOADED = "model_overloaded"
    MODEL_UNAVAILABLE = "model_unavailable"
    SERVICE_UNAVAILABLE = "service_unavailable"

    # Response Issues
    TIMEOUT = "timeout"
    CONTENT_FILTERED = "content_filtered"
    MAX_TOKENS_REACHED = "max_tokens_reached"

    # Network Issues
    NETWORK_ERROR = "network_error"
    CONNECTION_ERROR = "connection_error"

    # Generic
    UNKNOWN_ERROR = "unknown_error"
    INTERNAL_ERROR = "internal_error"


def get_user_friendly_message(error_code: ErrorCode, original_message: str = "") -> str:
    """
    Get a user-friendly error message based on the error code.

    Args:
        error_code: The standardized error code
        original_message: Original error message for context

    Returns:
        User-friendly error message with actionable guidance
    """
    messages = {
        ErrorCode.AUTHENTICATION_FAILED: "Authentication failed. Please check your API key in settings.",
        ErrorCode.API_KEY_MISSING: "API key not configured. Please add your API key in settings.",
        ErrorCode.API_KEY_INVALID: "Invalid API key. Please check your API key in settings.",
        ErrorCode.UNAUTHORIZED: "Access denied. Please verify your credentials.",

        ErrorCode.RATE_LIMITED: "Rate limit exceeded. Please wait a moment and try again.",
        ErrorCode.QUOTA_EXCEEDED: "API quota exceeded. Please check your usage limits.",

        ErrorCode.INVALID_REQUEST: "Invalid request. Please check your input and try again.",
        ErrorCode.INVALID_MODEL: "Model not available. Please select a different model.",
        ErrorCode.INVALID_PARAMETERS: "Invalid parameters. Please adjust your settings.",

        ErrorCode.MODEL_OVERLOADED: "Model is currently overloaded. Please try again in a moment.",
        ErrorCode.MODEL_UNAVAILABLE: "Model is temporarily unavailable. Please try a different model.",
        ErrorCode.SERVICE_UNAVAILABLE: "Service is temporarily unavailable. Please try again later.",

        ErrorCode.TIMEOUT: "Request timed out. Please try again with a shorter prompt or lower max tokens.",
        ErrorCode.CONTENT_FILTERED: "Response was filtered due to content policy. Please rephrase your prompt.",
        ErrorCode.MAX_TOKENS_REACHED: "Response reached maximum token limit. Try increasing max tokens in settings.",

        ErrorCode.NETWORK_ERROR: "Network error. Please check your connection and try again.",
        ErrorCode.CONNECTION_ERROR: "Connection failed. Please check your connection and try again.",

        ErrorCode.UNKNOWN_ERROR: f"An unexpected error occurred: {original_message}",
        ErrorCode.INTERNAL_ERROR: "Internal server error. Please try again later.",
    }

    return messages.get(error_code, f"Error: {original_message}")


def categorize_error(exception: Exception) -> ErrorCode:
    """
    Categorize an exception into a standardized error code.

    Args:
        exception: The exception to categorize

    Returns:
        Appropriate ErrorCode for the exception
    """
    error_str = str(exception).lower()

    # Authentication errors
    if any(keyword in error_str for keyword in ["api key", "authentication", "401", "unauthorized"]):
        return ErrorCode.AUTHENTICATION_FAILED

    # Rate limiting
    if any(keyword in error_str for keyword in ["rate limit", "429", "too many requests"]):
        return ErrorCode.RATE_LIMITED

    # Quota issues
    if any(keyword in error_str for keyword in ["quota", "exceeded"]):
        return ErrorCode.QUOTA_EXCEEDED

    # Model issues
    if any(keyword in error_str for keyword in ["overloaded", "503"]):
        return ErrorCode.MODEL_OVERLOADED

    if any(keyword in error_str for keyword in ["unavailable", "502", "504"]):
        return ErrorCode.SERVICE_UNAVAILABLE

    # Timeout
    if any(keyword in error_str for keyword in ["timeout", "timed out"]):
        return ErrorCode.TIMEOUT

    # Content filtering
    if any(keyword in error_str for keyword in ["safety", "blocked", "filter", "content policy"]):
        return ErrorCode.CONTENT_FILTERED

    # Network errors
    if any(keyword in error_str for keyword in ["connection", "network", "dns"]):
        return ErrorCode.NETWORK_ERROR

    # Default to unknown
    return ErrorCode.UNKNOWN_ERROR
