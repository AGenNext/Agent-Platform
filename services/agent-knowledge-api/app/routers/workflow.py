from fastapi import APIRouter, HTTPException

from app.db.surrealdb import db

router = APIRouter(prefix="/workflow", tags=["workflow"])


@router.get("/{objective_id}")
async def get_workflow_run(objective_id: str):
    """Return the full execution graph for an objective: tasks + artifacts + trust records."""
    try:
        obj_res = await db.query(
            "SELECT * FROM type::thing('objective', $id)",
            {"id": objective_id},
        )
        task_res = await db.query(
            "SELECT * FROM task WHERE objective_id = type::thing('objective', $id) ORDER BY created_at ASC",
            {"id": objective_id},
        )
        artifact_res = await db.query(
            "SELECT * FROM artifact WHERE objective_id = type::thing('objective', $id) ORDER BY created_at ASC",
            {"id": objective_id},
        )
        trust_res = await db.query(
            "SELECT * FROM trust_record WHERE objective_id = type::thing('objective', $id) ORDER BY evaluated_at DESC",
            {"id": objective_id},
        )
        usage_res = await db.query(
            """
            SELECT math::sum(cost_usd) AS total_cost_usd,
                   math::sum(tokens_in + tokens_out) AS total_tokens,
                   count() AS total_calls
            FROM usage_record WHERE objective_id = type::thing('objective', $id)
            """,
            {"id": objective_id},
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    obj_rows = obj_res[0].get("result", []) if obj_res else []
    if not obj_rows:
        raise HTTPException(status_code=404, detail="Objective not found")

    tasks = task_res[0].get("result", []) if task_res else []
    artifacts = artifact_res[0].get("result", []) if artifact_res else []
    trust_records = trust_res[0].get("result", []) if trust_res else []
    usage = (usage_res[0].get("result") or [{}])[0]

    # Compute run-level stats
    task_counts = {s: sum(1 for t in tasks if t.get("status") == s)
                   for s in ("pending", "running", "completed", "failed", "skipped")}
    artifact_counts = {s: sum(1 for a in artifacts if (a.get("eval_status") or "pending") == s)
                       for s in ("pending", "passed", "failed", "manual_review")}

    return {
        "objective": _serialize(obj_rows[0]),
        "tasks": [_serialize(t) for t in tasks],
        "artifacts": [_serialize(a) for a in artifacts],
        "trust_records": [_serialize(tr) for tr in trust_records],
        "stats": {
            "task_counts": task_counts,
            "artifact_counts": artifact_counts,
            "total_tasks": len(tasks),
            "total_artifacts": len(artifacts),
            "total_cost_usd": float(usage.get("total_cost_usd") or 0.0),
            "total_tokens": int(usage.get("total_tokens") or 0),
            "total_model_calls": int(usage.get("total_calls") or 0),
        },
    }


@router.get("/")
async def list_workflow_runs(limit: int = 20):
    """List recent objectives with their task/artifact counts."""
    try:
        results = await db.query(
            """
            SELECT
                objective.*,
                count(SELECT * FROM task WHERE objective_id = objective.id) AS task_count,
                count(SELECT * FROM artifact WHERE objective_id = objective.id) AS artifact_count
            FROM objective
            ORDER BY created_at DESC
            LIMIT $limit
            """,
            {"limit": limit},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        # Fallback: plain objective list if subquery syntax unsupported
        try:
            results = await db.query(
                "SELECT * FROM objective ORDER BY created_at DESC LIMIT $limit",
                {"limit": limit},
            )
            rows = results[0].get("result", []) if results else []
        except Exception as exc2:
            raise HTTPException(status_code=503, detail=str(exc2)) from exc2

    return [_serialize(r) for r in rows]


def _serialize(r: dict) -> dict:
    out = {}
    for k, v in r.items():
        if hasattr(v, "__str__") and not isinstance(v, (str, int, float, bool, list, dict, type(None))):
            out[k] = str(v)
        else:
            out[k] = v
    return out
