"""Pydantic schemas for request/response validation."""

from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


class Message(BaseModel):
    """Individual message in a conversation."""

    role: str = Field(..., description="Message role: 'user' or 'assistant'")
    content: str = Field(..., min_length=1, description="Message content")


class SearchResult(BaseModel):
    """Single search result item."""

    title: str
    snippet: str
    url: str


class SearchContext(BaseModel):
    """Contextual web search data supplied when invoking models."""

    query: str
    results: List[SearchResult]


class SearchResponse(BaseModel):
    """Response schema for web search."""

    query: str
    results: List[SearchResult]


class ChatRequest(BaseModel):
    """Request schema for chat endpoints."""

    prompt: str = Field(..., min_length=1, description="The prompt to send to the models")
    models: List[str] = Field(..., min_items=1, description="List of model IDs to query")
    temperature: float = Field(default=0.7, ge=0.0, le=2.0, description="Temperature for response generation (0.0-2.0)")
    max_tokens: int = Field(default=2000, ge=1, le=32000, description="Maximum number of tokens to generate (1-32000)")
    top_p: Optional[float] = Field(default=None, ge=0.0, le=1.0, description="Nucleus sampling parameter (0.0-1.0)")
    conversation_history: Optional[dict[str, List[Message]]] = Field(
        default=None,
        description="Optional conversation history per model. Key is model ID, value is list of messages"
    )
    api_overrides: Optional[dict[str, str]] = Field(
        default=None,
        description="Optional per-model API key overrides supplied by the client"
    )
    conversation_guide: Optional[str] = Field(
        default=None,
        description="Optional conversation-wide guidance/instructions to prepend to the model"
    )
    search_context: Optional["SearchContext"] = Field(
        default=None,
        description="Optional web search context to share with models"
    )

    @field_validator("models")
    @classmethod
    def validate_models(cls, v: List[str]) -> List[str]:
        """Validate that model IDs are not empty."""
        if not v:
            raise ValueError("At least one model must be specified")
        return v


class SingleChatRequest(BaseModel):
    """Request schema for single model chat endpoint."""

    prompt: str = Field(..., min_length=1, description="The prompt to send to the model")
    temperature: float = Field(default=0.7, ge=0.0, le=2.0, description="Temperature for response generation (0.0-2.0)")
    max_tokens: int = Field(default=2000, ge=1, le=32000, description="Maximum number of tokens to generate (1-32000)")
    top_p: Optional[float] = Field(default=None, ge=0.0, le=1.0, description="Nucleus sampling parameter (0.0-1.0)")


class ModelResponse(BaseModel):
    """Response schema for individual model responses."""

    model: str = Field(..., description="Model ID")
    response: str = Field(default="", description="Generated text response")
    tokens: Optional[int] = Field(default=None, description="Number of tokens in response")
    latency_ms: int = Field(..., description="Response time in milliseconds")
    error: Optional[str] = Field(default=None, description="Error message if request failed")
    error_code: Optional[str] = Field(default=None, description="Standardized error code for client handling")


class ChatResponse(BaseModel):
    """Response schema for multi-model chat endpoint."""

    responses: List[ModelResponse] = Field(..., description="List of responses from each model")
    total_latency_ms: int = Field(..., description="Total time for all parallel requests")


class ModelInfo(BaseModel):
    """Model metadata schema."""

    id: str = Field(..., description="Unique model identifier")
    name: str = Field(..., description="Human-readable model name")
    provider: str = Field(..., description="Model provider (e.g., Google, Groq, DeepSeek)")
    cost: str = Field(..., description="Cost information")


class ModelsResponse(BaseModel):
    """Response schema for models list endpoint."""

    models: List[ModelInfo] = Field(..., description="List of available models")


class HealthResponse(BaseModel):
    """Response schema for health check endpoint."""

    status: str = Field(..., description="Service status")
    timestamp: str = Field(..., description="Current timestamp in ISO format")


class AppleSignInRequest(BaseModel):
    """Request payload for Sign in with Apple verification."""

    identity_token: str = Field(..., description="JWT identity token returned by Apple")
    nonce: Optional[str] = Field(default=None, description="Optional nonce used during the authorization request")


class AppleSignInResponse(BaseModel):
    """Response for successful Sign in with Apple verification."""

    session_token: str = Field(..., description="Premium access session token to send with future requests")
    expires_in: int = Field(..., description="Session token validity in seconds")
