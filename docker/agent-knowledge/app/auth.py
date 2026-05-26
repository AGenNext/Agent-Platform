"""API key authentication and tenant context."""
import logging
import os
from fastapi import Header, HTTPException, Security
from fastapi.security import APIKeyHeader

logger = logging.getLogger(__name__)

_VALID_KEYS: set[str] = set(
    k.strip() for k in os.getenv("PLATFORM_API_KEYS", "").split(",") if k.strip()
)

_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def require_api_key(x_api_key: str | None = Security(_api_key_header)) -> str:
    if not _VALID_KEYS:
        logger.warning("PLATFORM_API_KEYS not set; running without auth (dev mode)")
        return "anonymous"
    if not x_api_key or x_api_key not in _VALID_KEYS:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")
    return x_api_key


async def resolve_workspace(
    x_workspace_id: str | None = Header(None, alias="X-Workspace-Id"),
    _key: str = Security(require_api_key),
) -> str | None:
    return x_workspace_id
