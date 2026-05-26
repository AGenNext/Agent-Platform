"""
FinOps / Lago billing adapter.

Fires a Lago event for every model usage record when LAGO_API_KEY is set.
Falls back to no-op silently so the platform works without billing configured.
"""
import logging
import os
import uuid
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

_LAGO_API_KEY = os.getenv("LAGO_API_KEY", "")
_LAGO_API_URL = os.getenv("LAGO_API_URL", "https://api.getlago.com/api/v1")
_LAGO_ENABLED = bool(_LAGO_API_KEY)


async def emit_usage_event(
    *,
    external_customer_id: str,
    event_code: str,
    transaction_id: Optional[str] = None,
    properties: Optional[dict] = None,
) -> None:
    if not _LAGO_ENABLED:
        return
    payload = {
        "event": {
            "transaction_id": transaction_id or str(uuid.uuid4()),
            "external_customer_id": external_customer_id,
            "code": event_code,
            "properties": properties or {},
        }
    }
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(
                f"{_LAGO_API_URL}/events",
                json=payload,
                headers={"Authorization": f"Bearer {_LAGO_API_KEY}"},
            )
            if resp.status_code not in (200, 201, 204):
                logger.warning("Lago event rejected", extra={"status": resp.status_code, "body": resp.text[:200]})
    except Exception as exc:
        logger.warning("Lago event failed", extra={"error": str(exc)})


async def emit_model_usage(
    *,
    workspace_id: Optional[str],
    objective_id: str,
    model_id: str,
    provider: str,
    input_tokens: int,
    output_tokens: int,
    cost_usd: float,
) -> None:
    customer_id = workspace_id or "platform"
    await emit_usage_event(
        external_customer_id=customer_id,
        event_code="model_tokens_used",
        properties={
            "objective_id": objective_id,
            "model_id": model_id,
            "provider": provider,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost_usd": str(cost_usd),
        },
    )
