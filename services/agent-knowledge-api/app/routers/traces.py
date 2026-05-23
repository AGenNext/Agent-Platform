from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/traces", tags=["traces"])


class TraceSpan(BaseModel):
    trace_id: str | None = None        # auto-generated if absent
    span_id: str | None = None
    parent_span: str | None = None
    from_agent: str | None = None
    to_agent: str | None = None
    objective_id: str | None = None
    task_id: str | None = None
    event_type: str = "event"
    payload: dict | None = None


class TraceRecord(BaseModel):
    id: str
    trace_id: str
    span_id: str
    parent_span: str | None
    from_agent: str | None
    to_agent: str | None
    objective_id: str | None
    task_id: str | None
    event_type: str
    payload: dict | None
    timestamp: str


@router.post("/", status_code=201, response_model=TraceRecord)
async def emit_span(body: TraceSpan):
    now = datetime.utcnow().isoformat()
    payload = {
        "@context": "https://schema.org",
        "@type": "Action",
        "trace_id": body.trace_id or str(uuid4()),
        "span_id": body.span_id or str(uuid4())[:8],
        "parent_span": body.parent_span,
        "from_agent": body.from_agent,
        "to_agent": body.to_agent,
        "objective_id": f"objective:{body.objective_id}" if body.objective_id else None,
        "task_id": f"task:{body.task_id}" if body.task_id else None,
        "event_type": body.event_type,
        "payload": body.payload,
        "timestamp": now,
    }
    try:
        result = await db.create("trace", payload)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    r = result[0] if isinstance(result, list) else result
    return _to_record(r)


@router.get("/", response_model=list[TraceRecord])
async def list_spans(
    trace_id: str | None = None,
    objective_id: str | None = None,
    event_type: str | None = None,
    limit: int = 100,
):
    where_parts = []
    vars: dict = {"limit": limit}
    if trace_id:
        where_parts.append("trace_id = $trace_id")
        vars["trace_id"] = trace_id
    if objective_id:
        where_parts.append("objective_id = type::thing('objective', $objective_id)")
        vars["objective_id"] = objective_id
    if event_type:
        where_parts.append("event_type = $event_type")
        vars["event_type"] = event_type

    where = f"WHERE {' AND '.join(where_parts)}" if where_parts else ""
    sql = f"SELECT * FROM trace {where} ORDER BY timestamp DESC LIMIT $limit"

    try:
        results = await db.query(sql, vars)
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_record(r) for r in rows]


@router.get("/{trace_id}/spans", response_model=list[TraceRecord])
async def get_trace(trace_id: str):
    """Return all spans for a single trace_id, ordered by timestamp."""
    try:
        results = await db.query(
            "SELECT * FROM trace WHERE trace_id = $id ORDER BY timestamp ASC",
            {"id": trace_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_record(r) for r in rows]


def _to_record(r: dict) -> TraceRecord:
    def strip(v: object, prefix: str) -> str | None:
        if v is None:
            return None
        s = str(v)
        return s.removeprefix(prefix) if s.startswith(prefix) else s

    return TraceRecord(
        id=str(r.get("id", "")),
        trace_id=r.get("trace_id", ""),
        span_id=r.get("span_id", ""),
        parent_span=r.get("parent_span"),
        from_agent=r.get("from_agent"),
        to_agent=r.get("to_agent"),
        objective_id=strip(r.get("objective_id"), "objective:"),
        task_id=strip(r.get("task_id"), "task:"),
        event_type=r.get("event_type", "event"),
        payload=r.get("payload"),
        timestamp=str(r.get("timestamp", "")),
    )
