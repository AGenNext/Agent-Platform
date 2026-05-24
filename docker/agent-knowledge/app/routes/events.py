import asyncio
import json
from typing import AsyncGenerator, Optional

from fastapi import APIRouter
from fastapi.responses import StreamingResponse

from ..events import emit, list_events, list_objective_timeline

router = APIRouter(prefix="/events", tags=["events"])


@router.get("")
async def api_list_events(
    entity_type: Optional[str] = None,
    entity_id: Optional[str] = None,
    limit: int = 100,
):
    return await list_events(entity_type, entity_id, limit)


@router.get("/objectives/{objective_id}")
async def api_objective_timeline(objective_id: str, limit: int = 200):
    return await list_objective_timeline(objective_id, limit)


@router.get("/objectives/{objective_id}/stream")
async def api_objective_stream(objective_id: str):
    """SSE stream — polls every 2 s and pushes new events as they arrive."""
    async def generator() -> AsyncGenerator[str, None]:
        seen: set[str] = set()
        while True:
            try:
                events = await list_objective_timeline(objective_id, limit=200)
                for ev in events:
                    if ev["id"] not in seen:
                        seen.add(ev["id"])
                        yield f"data: {json.dumps(ev)}\n\n"
            except Exception:
                yield "data: {\"error\": \"stream error\"}\n\n"
            await asyncio.sleep(2)

    return StreamingResponse(
        generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("")
async def api_emit(body: dict):
    return await emit(
        entity_type=body.get("entity_type", "custom"),
        entity_id=body.get("entity_id", ""),
        event_type=body.get("event_type", "custom"),
        payload=body.get("payload"),
    )
