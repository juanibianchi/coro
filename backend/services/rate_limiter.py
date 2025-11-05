import asyncio
import logging
import time
from typing import Optional, Dict, Tuple

from fastapi import HTTPException, Request, status

try:
    from redis.asyncio import Redis
except ImportError:  # pragma: no cover - redis is optional for tests
    Redis = None  # type: ignore

logger = logging.getLogger(__name__)


class RateLimitExceeded(Exception):
    """Raised when a caller exceeds the configured rate limit."""

    def __init__(self, retry_after: int):
        super().__init__("Rate limit exceeded")
        self.retry_after = retry_after


class BaseLimiterBackend:
    """Interface for limiter backends."""

    async def acquire(self, key: str, limit: int, window: int) -> None:
        raise NotImplementedError

    async def close(self) -> None:  # pragma: no cover - optional override
        return


class RedisLimiterBackend(BaseLimiterBackend):
    """Redis based fixed window rate limiter."""

    def __init__(self, redis: Redis):
        self.redis = redis

    async def acquire(self, key: str, limit: int, window: int) -> None:
        counter = await self.redis.incr(key)
        if counter == 1:
            await self.redis.expire(key, window)
        if counter > limit:
            ttl = await self.redis.ttl(key)
            raise RateLimitExceeded(retry_after=max(ttl, 1))

    async def close(self) -> None:
        await self.redis.close()


class InMemoryLimiterBackend(BaseLimiterBackend):
    """Fallback limiter for local development without Redis."""

    def __init__(self):
        self._buckets: Dict[str, list[float]] = {}
        self._lock = asyncio.Lock()

    async def acquire(self, key: str, limit: int, window: int) -> None:
        now = time.monotonic()
        threshold = now - window

        async with self._lock:
            bucket = self._buckets.setdefault(key, [])
            # Drop timestamps outside the window
            while bucket and bucket[0] <= threshold:
                bucket.pop(0)

            if len(bucket) >= limit:
                retry_after = int(bucket[0] + window - now) + 1
                raise RateLimitExceeded(retry_after=retry_after)

            bucket.append(now)


class PremiumSessionStore:
    """Tracks premium sessions granted via Sign in with Apple."""

    def __init__(self, redis: Optional[Redis], ttl_seconds: int):
        self.redis = redis
        self.ttl = ttl_seconds
        self._sessions: Dict[str, Tuple[str, float]] = {}
        self._lock = asyncio.Lock()

    async def add(self, token: str, user_id: str) -> None:
        expires_at = time.time() + self.ttl
        if self.redis:
            key = f"coro:premium:{token}"
            await self.redis.set(key, user_id, ex=self.ttl)
        else:
            async with self._lock:
                self._sessions[token] = (user_id, expires_at)

    async def exists(self, token: str) -> bool:
        if not token:
            return False

        if self.redis:
            key = f"coro:premium:{token}"
            return await self.redis.exists(key) == 1

        async with self._lock:
            entry = self._sessions.get(token)
            if not entry:
                return False
            user_id, expires_at = entry
            if expires_at < time.time():
                self._sessions.pop(token, None)
                return False
            return True


class RateLimiter:
    """High-level rate limiter service with Redis + fallback backends."""

    def __init__(
        self,
        redis_url: Optional[str],
        limits: Dict[str, Dict[str, int]],
        premium_session_ttl: int,
    ):
        self.redis_url = redis_url
        self.limits = limits
        self.backend: BaseLimiterBackend | None = None
        self.sessions: PremiumSessionStore | None = None
        self.premium_session_ttl = premium_session_ttl
        self.initialized = False

    async def initialize(self) -> None:
        if self.initialized:
            return

        redis_client: Optional[Redis] = None
        if self.redis_url and Redis is not None:
            try:
                redis_client = Redis.from_url(self.redis_url, decode_responses=True)
                await redis_client.ping()
                logger.info("Connected to Redis for rate limiting")
            except Exception as exc:  # pragma: no cover - best effort connection
                logger.warning("Failed to connect to Redis (%s); falling back to in-memory limiter", exc)
                redis_client = None

        if redis_client:
            self.backend = RedisLimiterBackend(redis_client)
        else:
            self.backend = InMemoryLimiterBackend()

        self.sessions = PremiumSessionStore(redis_client, self.premium_session_ttl)
        self.initialized = True

    async def close(self) -> None:
        if isinstance(self.backend, RedisLimiterBackend):
            await self.backend.close()
        self.initialized = False

    async def register_premium_session(self, token: str, user_id: str) -> None:
        if not self.sessions:
            raise RuntimeError("RateLimiter not initialized")
        await self.sessions.add(token, user_id)

    async def is_premium(self, token: Optional[str]) -> bool:
        if not self.sessions or not token:
            return False
        return await self.sessions.exists(token)

    async def check(self, key: str, tier: str) -> None:
        if not self.backend:
            raise RuntimeError("RateLimiter not initialized")

        tier_config = self.limits.get(tier) or self.limits.get("anonymous")
        limit = tier_config["limit"]
        window = tier_config["window"]

        bucket_key = f"coro:rl:{tier}:{key}"
        await self.backend.acquire(bucket_key, limit, window)


# Global instance managed during FastAPI startup/shutdown
rate_limiter: Optional[RateLimiter] = None


async def init_rate_limiter(config) -> None:
    """Initialize the shared rate limiter instance."""
    global rate_limiter
    rate_limiter = RateLimiter(
        redis_url=config.REDIS_URL,
        limits=config.RATE_LIMITS,
        premium_session_ttl=config.PREMIUM_SESSION_TTL,
    )
    await rate_limiter.initialize()


async def shutdown_rate_limiter() -> None:
    """Dispose the rate limiter backend."""
    if rate_limiter:
        await rate_limiter.close()


async def enforce_rate_limit(request: Request) -> None:
    """FastAPI dependency that enforces the configured rate limits."""
    if rate_limiter is None or not rate_limiter.initialized:
        return

    # Allow internal automation with master API token to bypass limits
    from backend.config import config

    auth_header = request.headers.get("authorization")
    if (
        config.CORO_API_TOKEN
        and auth_header
        and auth_header == f"Bearer {config.CORO_API_TOKEN}"
    ):
        return

    session_token = request.headers.get("x-coro-session")
    device_id = request.headers.get("x-coro-device")

    tier = "anonymous"
    if session_token and await rate_limiter.is_premium(session_token):
        tier = "premium"
    elif device_id:
        tier = "authenticated"

    identifier = session_token or device_id or request.client.host or "anonymous"

    try:
        await rate_limiter.check(identifier, tier)
    except RateLimitExceeded as exc:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please slow down.",
            headers={"Retry-After": str(exc.retry_after)},
        ) from exc
