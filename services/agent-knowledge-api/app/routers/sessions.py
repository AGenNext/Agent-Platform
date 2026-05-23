from typing import Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/sessions", tags=["sessions"])


def _s(v: Any) -> Any:
    if hasattr(v, "__str__") and ":" in str(v) and not isinstance(v, (str, int, float, bool)):
        return str(v)
    if isinstance(v, dict):
        return {k: _s(val) for k, val in v.items()}
    if isinstance(v, list):
        return [_s(i) for i in v]
    return v


class SessionCreate(BaseModel):
    agent_id: str
    tenant_id: str
    user_id: str | None = None
    title: str | None = None
    channel: str = "api"
    model_id: str | None = None


class MessageCreate(BaseModel):
    role: str = "user"
    content: str
    content_type: str = "text"
    tool_name: str | None = None
    tool_call_id: str | None = None
    tool_input: dict | None = None
    tool_output: str | None = None
    tokens_in: int = 0
    tokens_out: int = 0
    cost_usd: float = 0.0
    model_id: str | None = None
    latency_ms: int | None = None
    metadata: dict = {}


@router.post("/")
async def create_session(body: SessionCreate):
    import uuid
    session_id = f"sess-{uuid.uuid4().hex[:12]}"
    result = await db.query(
        """
        CREATE session SET
            session_id  = $session_id,
            agent_id    = $agent_id,
            tenant_id   = $tenant_id,
            user_id     = $user_id,
            title       = $title,
            channel     = $channel,
            model_id    = $model_id,
            status      = 'active',
            started_at  = time::now(),
            last_active = time::now()
        """,
        {
            "session_id": session_id,
            "agent_id": body.agent_id,
            "tenant_id": body.tenant_id,
            "user_id": body.user_id,
            "title": body.title or f"Session {session_id[:8]}",
            "channel": body.channel,
            "model_id": body.model_id,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to create session")
    return _s(rows[0])


@router.get("/")
async def list_sessions(
    tenant_id: str | None = None,
    agent_id: str | None = None,
    status: str | None = None,
    limit: int = 50,
):
    filters = []
    params: dict = {"limit": limit}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if agent_id:
        filters.append("agent_id = $agent_id")
        params["agent_id"] = agent_id
    if status:
        filters.append("status = $status")
        params["status"] = status
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(
        f"SELECT * FROM session {where} ORDER BY last_active DESC LIMIT $limit",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/{session_id}")
async def get_session(session_id: str):
    result = await db.query(
        "SELECT * FROM session WHERE session_id = $session_id LIMIT 1",
        {"session_id": session_id},
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(404, "Session not found")
    return _s(rows[0])


@router.post("/{session_id}/messages")
async def add_message(session_id: str, body: MessageCreate):
    # Verify session exists
    sess = await db.query(
        "SELECT id FROM session WHERE session_id = $session_id LIMIT 1",
        {"session_id": session_id},
    )
    rows = sess[0].get("result", []) if sess else []
    if not rows:
        raise HTTPException(404, "Session not found")
    session_ref = rows[0]["id"]

    result = await db.query(
        """
        CREATE message SET
            session_id   = $session_ref,
            tenant_id    = $tenant_id,
            role         = $role,
            content      = $content,
            content_type = $content_type,
            tool_name    = $tool_name,
            tool_call_id = $tool_call_id,
            tool_input   = $tool_input,
            tool_output  = $tool_output,
            tokens_in    = $tokens_in,
            tokens_out   = $tokens_out,
            cost_usd     = $cost_usd,
            model_id     = $model_id,
            latency_ms   = $latency_ms,
            metadata     = $metadata,
            created_at   = time::now()
        """,
        {
            "session_ref": session_ref,
            "tenant_id": (await db.query(
                "SELECT VALUE tenant_id FROM ONLY session WHERE session_id = $s LIMIT 1",
                {"s": session_id},
            ))[0].get("result") or "platform",
            "role": body.role,
            "content": body.content,
            "content_type": body.content_type,
            "tool_name": body.tool_name,
            "tool_call_id": body.tool_call_id,
            "tool_input": body.tool_input,
            "tool_output": body.tool_output,
            "tokens_in": body.tokens_in,
            "tokens_out": body.tokens_out,
            "cost_usd": body.cost_usd,
            "model_id": body.model_id,
            "latency_ms": body.latency_ms,
            "metadata": body.metadata,
        },
    )
    msg_rows = result[0].get("result", []) if result else []
    if not msg_rows:
        raise HTTPException(500, "Failed to create message")
    return _s(msg_rows[0])


@router.get("/{session_id}/messages")
async def list_messages(session_id: str, limit: int = 100):
    result = await db.query(
        """
        SELECT * FROM message
        WHERE session_id.session_id = $session_id
        ORDER BY created_at ASC
        LIMIT $limit
        """,
        {"session_id": session_id, "limit": limit},
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.patch("/{session_id}/status")
async def update_session_status(session_id: str, status: str):
    valid = {"active", "idle", "completed", "archived", "error"}
    if status not in valid:
        raise HTTPException(400, f"status must be one of {valid}")
    await db.query(
        "UPDATE session SET status = $status WHERE session_id = $session_id",
        {"session_id": session_id, "status": status},
    )
    return {"session_id": session_id, "status": status}
