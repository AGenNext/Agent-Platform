"""
Agent-Team — agent lifecycle and A2A handoffs backed by SurrealDB.

Graph model:
    agent:a  -[handoff]->  agent:b

SurrealQL traversal:
    SELECT ->handoff->agents AS downstream FROM agents:id
    SELECT <-handoff<-agents AS upstream   FROM agents:id
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db


# ── Agents ───────────────────────────────────────────────────────────────────

async def create_agent(run_id: str, agent_role: str) -> Dict[str, Any]:
    async with get_db() as db:
        record = {
            "agent_role": agent_role,
            "run_id": run_id,
            "status": "idle",
            "created_at": _now(),
        }
        result = await db.create("agents", record)
    return _norm(result[0] if isinstance(result, list) else result)


async def get_agent(agent_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        result = await db.select(f"agents:{agent_id}")
    return _norm(result) if result else None


async def list_agents(run_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM agents WHERE run_id = $run_id ORDER BY created_at",
            {"run_id": run_id},
        )
    return [_norm(r) for r in _rows(results)]


async def update_agent_status(agent_id: str, status: str) -> Dict[str, Any]:
    async with get_db() as db:
        result = await db.merge(f"agents:{agent_id}", {"status": status})
    return _norm(result)


# ── Tasks ────────────────────────────────────────────────────────────────────

async def create_task(
    agent_id: str,
    description: str,
    skill_id: Optional[str] = None,
) -> Dict[str, Any]:
    async with get_db() as db:
        record = {
            "agent_id": agent_id,
            "description": description,
            "skill_id": skill_id,
            "status": "pending",
            "started_at": _now(),
        }
        result = await db.create("agent_tasks", record)
    return _norm(result[0] if isinstance(result, list) else result)


async def complete_task(
    task_id: str,
    output_ref: Optional[str] = None,
    status: str = "completed",
) -> Dict[str, Any]:
    async with get_db() as db:
        result = await db.merge(f"agent_tasks:{task_id}", {
            "status": status,
            "output_ref": output_ref,
            "completed_at": _now(),
        })
    return _norm(result)


async def list_tasks(agent_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM agent_tasks WHERE agent_id = $agent_id ORDER BY started_at",
            {"agent_id": agent_id},
        )
    return [_norm(r) for r in _rows(results)]


# ── A2A Handoffs (graph edge) ─────────────────────────────────────────────────

async def create_handoff(
    source_agent_id: str,
    target_agent_id: str,
    context: str = "",
    payload: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Creates a directed graph edge:
        agents:{source} -[handoff]-> agents:{target}

    Queryable with SurrealQL graph traversal:
        SELECT ->handoff->agents FROM agents:{source}
    """
    async with get_db() as db:
        result = await db.query(
            """
            RELATE $src->handoff->$tgt CONTENT {
                context:        $context,
                payload:        $payload,
                handoff_status: 'initiated',
                created_at:     time::now()
            }
            """,
            {
                "src": f"agents:{source_agent_id}",
                "tgt": f"agents:{target_agent_id}",
                "context": context,
                "payload": payload or {},
            },
        )
    rows = _rows(result)
    return _norm(rows[0]) if rows else {}


async def get_handoff_chain(agent_id: str) -> List[Dict[str, Any]]:
    """Return all agents downstream of agent_id via graph traversal."""
    async with get_db() as db:
        results = await db.query(
            "SELECT ->handoff->agents.* AS downstream FROM $agent",
            {"agent": f"agents:{agent_id}"},
        )
    rows = _rows(results)
    downstream = rows[0].get("downstream", []) if rows else []
    return [_norm(a) for a in downstream]


async def list_handoffs(run_id: str) -> List[Dict[str, Any]]:
    """All handoffs for a given workflow run via correlated agent lookup."""
    async with get_db() as db:
        results = await db.query(
            """
            SELECT handoff.*
            FROM handoff
            WHERE in IN (SELECT id FROM agents WHERE run_id = $run_id)
            ORDER BY handoff.created_at
            """,
            {"run_id": run_id},
        )
    return [_norm(r) for r in _rows(results)]


# ── Helpers ──────────────────────────────────────────────────────────────────

def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _rows(result: Any) -> List[Dict[str, Any]]:
    if not result:
        return []
    if isinstance(result, list) and result and isinstance(result[0], dict):
        return result[0].get("result", result)
    return result if isinstance(result, list) else []


def _norm(record: Dict[str, Any]) -> Dict[str, Any]:
    if "id" in record:
        record["id"] = str(record["id"])
    return record
