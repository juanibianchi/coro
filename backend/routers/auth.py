import logging
import uuid

from fastapi import APIRouter, HTTPException, status

from backend.config import config
from backend.models.schemas import AppleSignInRequest, AppleSignInResponse
from backend.services.apple_auth import AppleSignInError, AppleSignInVerifier
from backend.services.rate_limiter import rate_limiter

logger = logging.getLogger(__name__)
router = APIRouter()

_apple_verifier = AppleSignInVerifier(
    client_id=config.APPLE_CLIENT_ID,
    skip_verification=config.APPLE_SKIP_VERIFICATION,
)


@router.post("/auth/apple", response_model=AppleSignInResponse)
async def verify_apple_sign_in(payload: AppleSignInRequest) -> AppleSignInResponse:
    """Accept Sign in with Apple tokens and return a premium session."""
    if rate_limiter is None or not rate_limiter.initialized:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Rate limiter not initialized",
        )

    try:
        claims = await _apple_verifier.verify_identity_token(payload.identity_token)
    except AppleSignInError as exc:
        logger.warning("Apple sign-in verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc

    user_id = claims.get("sub") or str(uuid.uuid4())
    session_token = str(uuid.uuid4())

    await rate_limiter.register_premium_session(session_token, user_id)

    logger.info("Granted premium session for Apple user %s", user_id)

    return AppleSignInResponse(
        session_token=session_token,
        expires_in=config.PREMIUM_SESSION_TTL,
    )
