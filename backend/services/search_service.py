"""Web search integration service."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import List

import httpx

from backend.config import config

logger = logging.getLogger(__name__)


@dataclass
class SearchResult:
    title: str
    snippet: str
    url: str


class SearchService:
    """Proxy service for web search results powered by Tavily."""

    def __init__(self) -> None:
        self.api_key = config.TAVILY_API_KEY
        self.endpoint = config.TAVILY_ENDPOINT.rstrip("/")

    async def search(self, query: str, *, count: int = 3) -> List[SearchResult]:
        if not self.api_key:
            logger.warning("Search requested but TAVILY_API_KEY is not configured")
            return []

        payload = {
            "api_key": self.api_key,
            "query": query,
            "max_results": count,
            "include_images": False,
            "include_answer": False,
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(self.endpoint, json=payload)
            response.raise_for_status()
            data = response.json()

        results: List[SearchResult] = []
        for item in data.get("results", [])[:count]:
            title = item.get("title") or "Untitled"
            snippet = item.get("content") or ""
            url = item.get("url") or ""
            results.append(SearchResult(title=title, snippet=snippet, url=url))

        return results


search_service = SearchService()


def should_search_for_query(query: str) -> bool:
    """
    Heuristic to decide whether a prompt likely needs fresh web context.
    """
    lowered = query.lower()
    keywords = [
        "latest", "recent", "today", "current", "breaking", "news",
        "update", "launched", "released", "price", "cost", "weather",
        "stock", "score", "result", "statistics", "trend", "vs", "versus",
        "compare", "review", "2024", "2025", "this week", "this month"
    ]

    for keyword in keywords:
        if keyword in lowered:
            logger.info("Search triggered by keyword '%s' in '%s'", keyword, query[:60])
            return True

    patterns = ["what happened", "what's new", "tell me about", "who won"]
    for pattern in patterns:
        if pattern in lowered:
            logger.info("Search triggered by pattern '%s' in '%s'", pattern, query[:60])
            return True

    return False
