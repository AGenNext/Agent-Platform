"""
Agent-Frameworks — workflow runtime and LangGraph-compatible checkpoint store
backed by SurrealDB.

LangGraph integration:
    from app.frameworks import SurrealDBCheckpointer
    checkpointer = SurrealDBCheckpointer()
    graph = StateGraph(...).compile(checkpointer=checkpointer)

SurrealQL used:
    - UPSERT for idempotent checkpoint saves
    - SELECT with ORDER BY + LIMIT 1 for latest checkpoint restore
    - Index on (thread_id, checkpoint_id) ensures uniqueness
"""

import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Iterator, List, Optional, Sequence, Tuple

from .db import get_db


# ── Workflow runs ─────────────────────────────────────────────────────────────

async def create_run(
    objective_id: str,
    definition_id: Optional[str] = None,
    initial_state: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    async with get_db() as db:
        record = {
            "objective_id": objective_id,
            "definition_id": definition_id,
            "status": "running",
            "state": initial_state or {},
            "started_at": _now(),
        }
        result = await db.create("workflow_runs", record)
    return _norm(result[0] if isinstance(result, list) else result)


async def get_run(run_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        result = await db.select(f"workflow_runs:{run_id}")
    return _norm(result) if result else None


async def list_runs(objective_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM workflow_runs WHERE objective_id = $oid ORDER BY started_at DESC",
            {"oid": objective_id},
        )
    return [_norm(r) for r in _rows(results)]


async def update_run_state(
    run_id: str,
    state: Dict[str, Any],
    status: Optional[str] = None,
) -> Dict[str, Any]:
    patch: Dict[str, Any] = {"state": state}
    if status:
        patch["status"] = status
    if status in ("completed", "failed"):
        patch["completed_at"] = _now()
    async with get_db() as db:
        result = await db.merge(f"workflow_runs:{run_id}", patch)
    return _norm(result)


async def complete_run(run_id: str, final_state: Dict[str, Any]) -> Dict[str, Any]:
    return await update_run_state(run_id, final_state, status="completed")


async def fail_run(run_id: str, error: str) -> Dict[str, Any]:
    return await update_run_state(
        run_id,
        {"error": error},
        status="failed",
    )


# ── LangGraph-compatible checkpoint store ─────────────────────────────────────

class SurrealDBCheckpointer:
    """
    Checkpoint saver compatible with LangGraph's BaseCheckpointSaver interface.

    Each checkpoint is stored as:
        checkpoints:{ulid}  with fields (thread_id, checkpoint_id, node_id, state_json, metadata)

    Restore always fetches the latest checkpoint for a thread ordered by created_at.

    Usage with LangGraph:
        from langgraph.graph import StateGraph
        from app.frameworks import SurrealDBCheckpointer

        checkpointer = SurrealDBCheckpointer()
        graph = StateGraph(MyState).compile(checkpointer=checkpointer)
    """

    # ── LangGraph sync protocol stubs (required by BaseCheckpointSaver) ──────

    def get(self, config: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        raise NotImplementedError("Use async aget() with this checkpointer")

    def put(self, config: Dict[str, Any], checkpoint: Dict[str, Any], metadata: Dict[str, Any]) -> Dict[str, Any]:
        raise NotImplementedError("Use async aput() with this checkpointer")

    def list(self, config: Dict[str, Any]) -> Iterator[Dict[str, Any]]:
        raise NotImplementedError("Use async alist() with this checkpointer")

    # ── Async implementation ─────────────────────────────────────────────────

    async def aget(self, config: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Return the latest checkpoint for the given thread_id."""
        thread_id = config.get("configurable", {}).get("thread_id", "default")
        checkpoint_id = config.get("configurable", {}).get("checkpoint_id")

        async with get_db() as db:
            if checkpoint_id:
                results = await db.query(
                    "SELECT * FROM checkpoints WHERE thread_id = $tid AND checkpoint_id = $cid LIMIT 1",
                    {"tid": thread_id, "cid": checkpoint_id},
                )
            else:
                results = await db.query(
                    "SELECT * FROM checkpoints WHERE thread_id = $tid ORDER BY created_at DESC LIMIT 1",
                    {"tid": thread_id},
                )
        rows = _rows(results)
        if not rows:
            return None
        row = rows[0]
        return {
            "v": 1,
            "id": row.get("checkpoint_id"),
            "ts": row.get("created_at"),
            "channel_values": json.loads(row.get("state_json", "{}")),
            "channel_versions": {},
            "versions_seen": {},
            "pending_sends": [],
        }

    async def aput(
        self,
        config: Dict[str, Any],
        checkpoint: Dict[str, Any],
        metadata: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Save a checkpoint; upsert by (thread_id, checkpoint_id)."""
        thread_id = config.get("configurable", {}).get("thread_id", "default")
        checkpoint_id = checkpoint.get("id", str(uuid.uuid4()))
        node_id = metadata.get("source", "unknown")
        run_id = config.get("configurable", {}).get("run_id", "")

        state_json = json.dumps(checkpoint.get("channel_values", {}))

        async with get_db() as db:
            await db.query(
                """
                UPSERT checkpoints SET
                    run_id        = $run_id,
                    thread_id     = $tid,
                    checkpoint_id = $cid,
                    node_id       = $node_id,
                    state_json    = $state_json,
                    metadata      = $metadata,
                    created_at    = $created_at
                WHERE thread_id = $tid AND checkpoint_id = $cid
                """,
                {
                    "run_id": run_id,
                    "tid": thread_id,
                    "cid": checkpoint_id,
                    "node_id": node_id,
                    "state_json": state_json,
                    "metadata": metadata,
                    "created_at": _now(),
                },
            )

        return {**config, "configurable": {**config.get("configurable", {}), "checkpoint_id": checkpoint_id}}

    async def alist(self, config: Dict[str, Any]) -> List[Dict[str, Any]]:
        """List all checkpoints for a thread in descending order."""
        thread_id = config.get("configurable", {}).get("thread_id", "default")
        async with get_db() as db:
            results = await db.query(
                "SELECT * FROM checkpoints WHERE thread_id = $tid ORDER BY created_at DESC",
                {"tid": thread_id},
            )
        rows = _rows(results)
        return [
            {
                "v": 1,
                "id": r.get("checkpoint_id"),
                "ts": r.get("created_at"),
                "channel_values": json.loads(r.get("state_json", "{}")),
                "metadata": r.get("metadata", {}),
            }
            for r in rows
        ]

    async def adelete_thread(self, thread_id: str) -> int:
        """Delete all checkpoints for a thread. Returns count deleted."""
        async with get_db() as db:
            result = await db.query(
                "DELETE FROM checkpoints WHERE thread_id = $tid RETURN BEFORE",
                {"tid": thread_id},
            )
        return len(_rows(result))


# ── Convenience: raw checkpoint ops ──────────────────────────────────────────

async def save_checkpoint(
    run_id: str,
    thread_id: str,
    node_id: str,
    state: Dict[str, Any],
    metadata: Optional[Dict[str, Any]] = None,
) -> str:
    checkpoint_id = str(uuid.uuid4())
    checkpointer = SurrealDBCheckpointer()
    await checkpointer.aput(
        config={"configurable": {"thread_id": thread_id, "run_id": run_id}},
        checkpoint={"id": checkpoint_id, "channel_values": state},
        metadata={"source": node_id, **(metadata or {})},
    )
    return checkpoint_id


async def restore_checkpoint(thread_id: str, checkpoint_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
    checkpointer = SurrealDBCheckpointer()
    config: Dict[str, Any] = {"configurable": {"thread_id": thread_id}}
    if checkpoint_id:
        config["configurable"]["checkpoint_id"] = checkpoint_id
    return await checkpointer.aget(config)


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
