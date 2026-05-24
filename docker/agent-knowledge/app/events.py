"""
Runtime event trail — write and query structured events.

Every significant state change emits an event record. The SurrealDB EVENT
trigger handles objective status changes automatically; everything else calls
emit() directly.
"""
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db


async def emit(
    entity_type: str,
    entity_id: str,
    event_type: str,
    payload: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    async with get_db() as db:
        result = await db.create("events", {
            "entity_type": entity_type,
            "entity_id": entity_id,
            "event_type": event_type,
            "payload": payload or {},
            "occurred_at": _now(),
        })
    record = result[0] if isinstance(result, list) else result
    record["id"] = str(record["id"])
    return record


async def list_events(
    entity_type: Optional[str] = None,
    entity_id: Optional[str] = None,
    limit: int = 100,
) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if entity_type and entity_id:
            results = await db.query(
                "SELECT * FROM events WHERE entity_type = $et AND entity_id = $eid "
                "ORDER BY occurred_at DESC LIMIT $l",
                {"et": entity_type, "eid": entity_id, "l": limit},
            )
        elif entity_type:
            results = await db.query(
                "SELECT * FROM events WHERE entity_type = $et "
                "ORDER BY occurred_at DESC LIMIT $l",
                {"et": entity_type, "l": limit},
            )
        else:
            results = await db.query(
                "SELECT * FROM events ORDER BY occurred_at DESC LIMIT $l",
                {"l": limit},
            )
    return [_norm(r) for r in _rows(results)]


async def list_objective_timeline(objective_id: str, limit: int = 200) -> List[Dict[str, Any]]:
    """All events for an objective plus events for its artifacts and agents."""
    async with get_db() as db:
        results = await db.query(
            """
            SELECT * FROM events
            WHERE entity_id = $oid
               OR (entity_type = 'artifact' AND payload.objective_id = $oid)
            ORDER BY occurred_at ASC LIMIT $l
            """,
            {"oid": objective_id, "l": limit},
        )
    return [_norm(r) for r in _rows(results)]


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _rows(result):
    if not result:
        return []
    if isinstance(result, list) and result and isinstance(result[0], dict):
        return result[0].get("result", result)
    return result if isinstance(result, list) else []


def _norm(record: dict) -> dict:
    if "id" in record:
        record["id"] = str(record["id"])
    return record
