"""
Orchestrator router - Intelligent model recommendations and query analysis.

Provides endpoints for agentic CORO features like smart model suggestions
and query classification.
"""

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field
from typing import List

from backend.services.model_orchestrator import model_orchestrator, QueryType

router = APIRouter(prefix="/orchestrator", tags=["orchestrator"])


class ModelSuggestionResponse(BaseModel):
    """A suggested model for the user's query."""
    model_id: str
    model_name: str
    reason: str
    confidence: float = Field(ge=0.0, le=1.0)


class QueryAnalysisResponse(BaseModel):
    """Analysis of a query with model suggestions."""
    query: str
    query_type: str
    suggested_models: List[ModelSuggestionResponse]
    reasoning: str


@router.get("/analyze", response_model=QueryAnalysisResponse)
async def analyze_query(
    q: str = Query(..., min_length=3, description="Query to analyze"),
    selected: str = Query("", description="Comma-separated list of already selected model IDs")
) -> QueryAnalysisResponse:
    """
    Analyze a query and suggest which models would excel at answering it.

    This makes CORO agentic by intelligently recommending specialized models
    based on the query type (code, math, creative, analysis, etc.).

    Args:
        q: The user's question
        selected: Models already selected by the user (comma-separated)

    Returns:
        Query analysis with model suggestions and reasoning
    """
    # Parse selected models
    selected_models = [m.strip() for m in selected.split(",") if m.strip()]

    # Classify query
    query_type = model_orchestrator.classify_query(q)

    # Get suggestions
    suggestions = model_orchestrator.suggest_models(
        query=q,
        selected_models=selected_models,
        max_suggestions=2
    )

    # Build reasoning
    reasoning_map = {
        QueryType.CODE: "This appears to be a code-related query. Models specialized in code generation and debugging would be ideal.",
        QueryType.MATH: "This is a mathematical query. Models with strong logical reasoning capabilities are recommended.",
        QueryType.CREATIVE: "This is a creative query. Models that excel at expressive writing would provide the best results.",
        QueryType.ANALYSIS: "This requires deep analysis. Models with strong reasoning capabilities are recommended.",
        QueryType.NEWS: "This query needs current information. A model that works well with web context is ideal.",
        QueryType.TECHNICAL: "This is a technical query. Models with strong explanatory capabilities are recommended.",
        QueryType.COMPARISON: "This is a comparison query. Models that can provide balanced analysis are ideal.",
        QueryType.GENERAL: "This is a general knowledge query. A diverse set of models would provide varied perspectives.",
    }

    reasoning = reasoning_map.get(query_type, "Based on query analysis, these models would provide complementary perspectives.")

    return QueryAnalysisResponse(
        query=q,
        query_type=query_type.value,
        suggested_models=[
            ModelSuggestionResponse(
                model_id=s.model_id,
                model_name=s.model_name,
                reason=s.reason,
                confidence=s.confidence
            )
            for s in suggestions
        ],
        reasoning=reasoning
    )


@router.get("/optimal-models", response_model=List[str])
async def get_optimal_models(
    q: str = Query(..., min_length=3, description="Query to analyze")
) -> List[str]:
    """
    Get the optimal set of models for a query.

    Useful when the user hasn't selected any models yet.

    Returns:
        List of recommended model IDs
    """
    return model_orchestrator.get_optimal_model_set(q)
