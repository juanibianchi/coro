"""Search router providing web augmentation results with AI intelligence."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel

from backend.models.schemas import SearchResponse, SearchResult
from backend.services.search_service import search_service, should_search_for_query

router = APIRouter(prefix="/search", tags=["search"])


class SearchRecommendationResponse(BaseModel):
    """Response indicating whether search is recommended for a query."""
    should_search: bool
    reason: str


@router.get("", response_model=SearchResponse)
async def search_web(q: str = Query(..., min_length=3, description="Query to search for")) -> SearchResponse:
    """
    Search the web using Tavily AI.

    Returns optimized search results with snippets and source URLs.
    """
    try:
        results = await search_service.search(q)
    except HTTPException:
        raise
    except Exception as exc:  # pragma: no cover - upstream errors
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Search provider error"
        ) from exc

    return SearchResponse(query=q, results=[SearchResult(**r.__dict__) for r in results])


@router.get("/recommend", response_model=SearchRecommendationResponse)
async def recommend_search(q: str = Query(..., min_length=3, description="Query to analyze")) -> SearchRecommendationResponse:
    """
    Analyze a query and recommend whether web search would be beneficial.

    Uses keyword detection to identify queries that need current information.
    """
    should_search = should_search_for_query(q)

    if should_search:
        reason = "Query contains time-sensitive or real-world keywords that would benefit from current web data"
    else:
        reason = "Query appears to be about general knowledge or concepts that don't require web search"

    return SearchRecommendationResponse(should_search=should_search, reason=reason)

