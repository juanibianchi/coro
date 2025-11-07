"""
Model Orchestrator - Intelligent routing of queries to specialized models.

This service analyzes queries and recommends which models are best suited
for different types of tasks, making CORO more agentic and intelligent.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from enum import Enum
from typing import List, Dict, Set

logger = logging.getLogger(__name__)


class QueryType(Enum):
    """Types of queries that can be detected."""
    CODE = "code"
    MATH = "math"
    CREATIVE = "creative"
    ANALYSIS = "analysis"
    NEWS = "news"
    GENERAL = "general"
    TECHNICAL = "technical"
    COMPARISON = "comparison"


class ModelSpecialty(Enum):
    """Model specializations based on observed strengths."""
    # Gemini excels at:
    GEMINI_WEB_CONTEXT = "web-augmented-responses"
    GEMINI_CREATIVE = "creative-writing"
    GEMINI_MULTIMODAL = "visual-reasoning"

    # Llama 70B excels at:
    LLAMA70B_REASONING = "deep-reasoning"
    LLAMA70B_ANALYSIS = "analytical-tasks"
    LLAMA70B_TECHNICAL = "technical-explanations"

    # Llama 8B excels at:
    LLAMA8B_QUICK = "quick-responses"
    LLAMA8B_SIMPLE = "simple-tasks"
    LLAMA8B_CONVERSATIONAL = "casual-chat"

    # Mixtral excels at:
    MIXTRAL_CODE = "code-generation"
    MIXTRAL_STRUCTURED = "structured-output"
    MIXTRAL_DEBUGGING = "code-debugging"

    # DeepSeek excels at:
    DEEPSEEK_MATH = "mathematical-reasoning"
    DEEPSEEK_RESEARCH = "research-tasks"
    DEEPSEEK_LOGIC = "logical-reasoning"


@dataclass
class ModelSuggestion:
    """A suggested model for the query."""
    model_id: str
    model_name: str
    reason: str
    confidence: float  # 0.0 to 1.0


class ModelOrchestrator:
    """
    Intelligent model recommendation system.

    Analyzes queries and suggests which models would perform best.
    """

    # Map query types to model IDs that excel at them
    QUERY_TYPE_SPECIALISTS: Dict[QueryType, List[str]] = {
        QueryType.CODE: ["mixtral", "llama-70b"],
        QueryType.MATH: ["deepseek", "llama-70b"],
        QueryType.CREATIVE: ["gemini", "llama-70b"],
        QueryType.ANALYSIS: ["llama-70b", "deepseek"],
        QueryType.NEWS: ["gemini"],  # Best with web context
        QueryType.GENERAL: ["gemini", "llama-70b", "llama-8b"],
        QueryType.TECHNICAL: ["llama-70b", "deepseek"],
        QueryType.COMPARISON: ["llama-70b", "gemini"],
    }

    # Model metadata
    MODEL_INFO = {
        "gemini": {
            "name": "Gemini 2.5 Flash",
            "strengths": ["creative writing", "web-augmented answers", "general knowledge"],
        },
        "llama-70b": {
            "name": "Llama 3.3 70B",
            "strengths": ["deep reasoning", "technical analysis", "comprehensive answers"],
        },
        "llama-8b": {
            "name": "Llama 3.1 8B",
            "strengths": ["quick responses", "simple tasks", "conversational chat"],
        },
        "mixtral": {
            "name": "Llama 4 Maverick (MoE)",
            "strengths": ["code generation", "debugging", "structured output"],
        },
        "deepseek": {
            "name": "DeepSeek V2.5",
            "strengths": ["mathematical reasoning", "logic problems", "research"],
        },
    }

    def classify_query(self, query: str) -> QueryType:
        """
        Classify a query into a type.

        Args:
            query: The user's question

        Returns:
            QueryType enum value
        """
        query_lower = query.lower()

        # Code-related keywords
        code_keywords = [
            "code", "function", "debug", "implement", "algorithm",
            "write a", "programming", "script", "bug", "error",
            "python", "javascript", "swift", "java", "rust", "go",
            "class", "method", "variable", "loop", "array"
        ]

        # Math keywords
        math_keywords = [
            "calculate", "equation", "solve", "math", "formula",
            "derivative", "integral", "probability", "statistics",
            "proof", "theorem", "algebra", "geometry"
        ]

        # Creative keywords
        creative_keywords = [
            "write", "story", "poem", "essay", "creative",
            "imagine", "describe", "explain like", "eli5",
            "metaphor", "analogy"
        ]

        # Analysis keywords
        analysis_keywords = [
            "analyze", "compare", "evaluate", "assess", "critique",
            "pros and cons", "advantages", "disadvantages", "trade-offs"
        ]

        # News/current events keywords
        news_keywords = [
            "news", "latest", "recent", "today", "this week",
            "what happened", "announced", "breaking"
        ]

        # Technical keywords
        technical_keywords = [
            "how does", "explain", "technical", "architecture",
            "system", "infrastructure", "protocol", "mechanism"
        ]

        # Comparison keywords
        comparison_keywords = [
            "vs", "versus", "compare", "difference between",
            "which is better", "should i use"
        ]

        # Check keywords in order of specificity
        if any(keyword in query_lower for keyword in code_keywords):
            return QueryType.CODE
        elif any(keyword in query_lower for keyword in math_keywords):
            return QueryType.MATH
        elif any(keyword in query_lower for keyword in creative_keywords):
            return QueryType.CREATIVE
        elif any(keyword in query_lower for keyword in comparison_keywords):
            return QueryType.COMPARISON
        elif any(keyword in query_lower for keyword in news_keywords):
            return QueryType.NEWS
        elif any(keyword in query_lower for keyword in technical_keywords):
            return QueryType.TECHNICAL
        elif any(keyword in query_lower for keyword in analysis_keywords):
            return QueryType.ANALYSIS
        else:
            return QueryType.GENERAL

    def suggest_models(
        self,
        query: str,
        selected_models: List[str],
        max_suggestions: int = 2
    ) -> List[ModelSuggestion]:
        """
        Suggest additional models that would complement the user's selection.

        Args:
            query: The user's question
            selected_models: Models already selected by user
            max_suggestions: Maximum number of suggestions to return

        Returns:
            List of ModelSuggestion objects
        """
        query_type = self.classify_query(query)
        logger.info(f"Query classified as: {query_type.value} - '{query[:50]}...'")

        # Get specialists for this query type
        specialists = self.QUERY_TYPE_SPECIALISTS.get(query_type, [])

        # Find specialists not already selected
        suggested_model_ids = [
            mid for mid in specialists
            if mid not in selected_models
        ]

        # Build suggestions
        suggestions: List[ModelSuggestion] = []

        for model_id in suggested_model_ids[:max_suggestions]:
            info = self.MODEL_INFO.get(model_id, {})
            model_name = info.get("name", model_id)
            strengths = info.get("strengths", [])

            # Create reason based on query type
            reason_map = {
                QueryType.CODE: "excels at code generation and debugging",
                QueryType.MATH: "specializes in mathematical reasoning",
                QueryType.CREATIVE: "great for creative and expressive writing",
                QueryType.ANALYSIS: "provides deep analytical insights",
                QueryType.NEWS: "works best with web-augmented context",
                QueryType.TECHNICAL: "excels at technical explanations",
                QueryType.COMPARISON: "provides balanced comparative analysis",
                QueryType.GENERAL: "offers comprehensive general knowledge",
            }

            reason = reason_map.get(query_type, "recommended for this type of query")

            # Calculate confidence based on position in specialist list
            confidence = 1.0 - (specialists.index(model_id) * 0.2)

            suggestions.append(ModelSuggestion(
                model_id=model_id,
                model_name=model_name,
                reason=reason,
                confidence=max(0.5, confidence)
            ))

        return suggestions

    def get_optimal_model_set(self, query: str) -> List[str]:
        """
        Get the optimal set of models for a query (if user hasn't selected any).

        Returns:
            List of recommended model IDs
        """
        query_type = self.classify_query(query)
        specialists = self.QUERY_TYPE_SPECIALISTS.get(query_type, ["gemini", "llama-70b"])

        # Always include at least 2-3 diverse perspectives
        if len(specialists) >= 3:
            return specialists[:3]
        elif len(specialists) == 2:
            return specialists + ["llama-8b"]  # Add a fast model for quick comparison
        else:
            return specialists + ["llama-70b", "llama-8b"]  # Add general-purpose models


# Global instance
model_orchestrator = ModelOrchestrator()
