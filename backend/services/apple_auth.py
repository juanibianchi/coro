import logging
import time
import uuid
from typing import Any, Dict, Optional

import httpx
from jose import jwt
from jose.exceptions import JWTError

APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
logger = logging.getLogger(__name__)


class AppleSignInError(Exception):
    """Raised when verification of an Apple identity token fails."""


class AppleSignInVerifier:
    """Verifies Sign in with Apple identity tokens."""

    def __init__(self, client_id: Optional[str], skip_verification: bool = False):
        self.client_id = client_id
        self.skip_verification = skip_verification or not client_id
        self._cached_keys: Optional[Dict[str, Any]] = None
        self._cache_expiry: float = 0.0

        if self.skip_verification:
            logger.warning(
                "APPLE_SKIP_VERIFICATION enabled or APPLE_CLIENT_ID missing. "
                "Identity tokens will NOT be cryptographically verified."
            )

    async def verify_identity_token(self, identity_token: str) -> Dict[str, Any]:
        """Validate an Apple identity token and return its claims."""
        if self.skip_verification:
            # Fabricate minimal payload
            return {"sub": str(uuid.uuid4())}

        try:
            header = jwt.get_unverified_header(identity_token)
        except JWTError as exc:
            raise AppleSignInError("Invalid identity token header") from exc

        kid = header.get("kid")
        if not kid:
            raise AppleSignInError("Identity token header missing 'kid'")

        jwks = await self._fetch_apple_keys()
        key = next((item for item in jwks.get("keys", []) if item.get("kid") == kid), None)
        if not key:
            raise AppleSignInError("Unable to locate signing key for identity token")

        try:
            return jwt.decode(
                identity_token,
                key,
                algorithms=["RS256"],
                audience=self.client_id,
                issuer="https://appleid.apple.com",
                options={"verify_at_hash": False},
            )
        except JWTError as exc:
            raise AppleSignInError("Identity token verification failed") from exc

    async def _fetch_apple_keys(self) -> Dict[str, Any]:
        """Fetch Apple's JWKS metadata, using a short-lived cache."""
        now = time.time()
        if self._cached_keys and now < self._cache_expiry:
            return self._cached_keys

        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(APPLE_KEYS_URL)
                response.raise_for_status()
                data = response.json()
                self._cached_keys = data
                self._cache_expiry = now + 60 * 15  # cache for 15 minutes
                return data
        except httpx.HTTPError as exc:  # pragma: no cover - network errors
            logger.error("Failed to download Apple public keys: %s", exc)
            raise AppleSignInError("Could not fetch Apple public keys") from exc
