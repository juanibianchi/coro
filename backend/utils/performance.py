"""Performance optimization utilities for HTTP requests and caching."""

import httpx
import logging
from functools import wraps
from typing import Optional, Callable, Any
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_sleep_log
)
from cachetools import TTLCache

logger = logging.getLogger(__name__)

# Global HTTP client with connection pooling
_http_client: Optional[httpx.AsyncClient] = None

# Response cache with 5-minute TTL and max 1000 entries
response_cache = TTLCache(maxsize=1000, ttl=300)


def get_http_client() -> httpx.AsyncClient:
    """
    Get or create a shared HTTP client with connection pooling.

    Benefits:
    - Reuses TCP connections for better performance
    - Reduces latency by avoiding connection overhead
    - Handles timeouts consistently

    Returns:
        Configured httpx.AsyncClient instance
    """
    global _http_client

    if _http_client is None or _http_client.is_closed:
        # Create client with aggressive connection pooling and reasonable timeouts
        _http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                connect=10.0,  # 10 seconds to establish connection
                read=60.0,     # 60 seconds to read response
                write=10.0,    # 10 seconds to send request
                pool=5.0       # 5 seconds to acquire connection from pool
            ),
            limits=httpx.Limits(
                max_connections=100,      # Total connections
                max_keepalive_connections=20,  # Reusable connections
                keepalive_expiry=30.0    # Keep connections alive for 30s
            ),
            http2=True,  # Enable HTTP/2 for better performance
            follow_redirects=True
        )
        logger.info("Created new HTTP client with connection pooling")

    return _http_client


async def close_http_client():
    """Close the global HTTP client and release resources."""
    global _http_client

    if _http_client and not _http_client.is_closed:
        await _http_client.aclose()
        _http_client = None
        logger.info("Closed HTTP client")


def with_retry(
    max_attempts: int = 3,
    min_wait: float = 1.0,
    max_wait: float = 10.0
):
    """
    Decorator to add retry logic with exponential backoff.

    Args:
        max_attempts: Maximum number of retry attempts
        min_wait: Minimum wait time between retries (seconds)
        max_wait: Maximum wait time between retries (seconds)

    Returns:
        Decorated function with retry logic
    """
    def decorator(func: Callable) -> Callable:
        @retry(
            stop=stop_after_attempt(max_attempts),
            wait=wait_exponential(multiplier=1, min=min_wait, max=max_wait),
            retry=retry_if_exception_type((
                httpx.ConnectError,
                httpx.ConnectTimeout,
                httpx.ReadTimeout,
                httpx.PoolTimeout
            )),
            before_sleep=before_sleep_log(logger, logging.WARNING),
            reraise=True
        )
        @wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                return await func(*args, **kwargs)
            except Exception as e:
                logger.error(f"Request failed after {max_attempts} attempts: {str(e)}")
                raise

        return wrapper

    return decorator


def cached_response(cache_key_fn: Optional[Callable] = None):
    """
    Decorator to cache function responses.

    Args:
        cache_key_fn: Optional function to generate cache key from function args

    Returns:
        Decorated function with caching
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            if cache_key_fn:
                cache_key = cache_key_fn(*args, **kwargs)
            else:
                # Default: use function name and stringified args
                cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"

            # Check cache
            if cache_key in response_cache:
                logger.debug(f"Cache hit for {cache_key}")
                return response_cache[cache_key]

            # Execute function and cache result
            result = await func(*args, **kwargs)
            response_cache[cache_key] = result
            logger.debug(f"Cached result for {cache_key}")

            return result

        return wrapper

    return decorator


def clear_cache():
    """Clear all cached responses."""
    response_cache.clear()
    logger.info("Cleared response cache")


def get_cache_stats() -> dict[str, Any]:
    """
    Get cache statistics.

    Returns:
        Dictionary with cache metrics
    """
    return {
        "size": len(response_cache),
        "max_size": response_cache.maxsize,
        "ttl": response_cache.ttl,
        "currsize": response_cache.currsize
    }
