"""
Model-Router — policy-driven model selection and FinOps cost tracking
backed by SurrealDB.

Routing logic:
    1. Load routing rule for task_type from SurrealDB
    2. Filter models by availability and max_cost_per_call
    3. Check daily budget remaining via SurrealQL aggregate
    4. Return selected model or fallback

FinOps:
    Every model call records a usage_record.
    Budget enforcement is enforced via SurrealQL:
        SELECT math::sum(cost_usd) FROM usage_records
        WHERE model_id = $mid AND recorded_at > time::now() - 1d
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db


# ── Routing ───────────────────────────────────────────────────────────────────

async def select_model(
    task_type: str,
    max_cost_override: Optional[float] = None,
) -> Dict[str, Any]:
    """
    Select the best available model for a task_type under routing policy.

    Returns {model_id, provider, estimated_cost, rationale} or raises.
    """
    rule = await get_routing_rule(task_type)
    if not rule or not rule.get("enabled"):
        return _fallback(task_type, "no_rule")

    models: List[Dict[str, Any]] = rule.get("models", [])
    max_cost = max_cost_override or rule.get("max_cost_per_call", 0.10)
    daily_budget = rule.get("daily_budget", 10.0)

    # Check how much budget is consumed today
    consumed = await _daily_spend(task_type)
    if consumed >= daily_budget:
        return _fallback(task_type, f"daily_budget_exhausted (${consumed:.4f} / ${daily_budget})")

    budget_remaining = daily_budget - consumed

    # Pick highest-priority model within cost constraint
    candidates = sorted(models, key=lambda m: m.get("priority", 99))
    for candidate in candidates:
        if candidate.get("max_cost_per_call", 0) <= max_cost:
            return {
                "model_id": candidate["model_id"],
                "provider": candidate["provider"],
                "estimated_cost": candidate.get("max_cost_per_call", 0.0),
                "rationale": f"priority={candidate.get('priority',0)}, budget_remaining=${budget_remaining:.4f}",
                "rule_id": rule.get("id"),
            }

    return _fallback(task_type, "no_candidate_within_cost")


async def get_routing_rule(task_type: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM routing_rules WHERE task_type = $tt AND enabled = true LIMIT 1",
            {"tt": task_type},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def list_routing_rules() -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query("SELECT * FROM routing_rules ORDER BY task_type")
    return [_norm(r) for r in _rows(results)]


async def upsert_routing_rule(rule: Dict[str, Any]) -> Dict[str, Any]:
    task_type = rule.get("task_type")
    async with get_db() as db:
        existing = await db.query(
            "SELECT id FROM routing_rules WHERE task_type = $tt LIMIT 1",
            {"tt": task_type},
        )
        rows = _rows(existing)
        if rows:
            rid = str(rows[0]["id"])
            result = await db.merge(rid, rule)
        else:
            result = await db.create("routing_rules", rule)
    return _norm(result[0] if isinstance(result, list) else result)


# ── FinOps: usage recording ───────────────────────────────────────────────────

async def record_usage(
    objective_id: str,
    model_id: str,
    provider: str,
    input_tokens: int,
    output_tokens: int,
    cost_usd: float,
    workspace_id: Optional[str] = None,
) -> Dict[str, Any]:
    async with get_db() as db:
        record = {
            "objective_id": objective_id,
            "model_id": model_id,
            "provider": provider,
            "workspace_id": workspace_id,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost_usd": cost_usd,
            "recorded_at": _now(),
        }
        result = await db.create("usage_records", record)
    return _norm(result[0] if isinstance(result, list) else result)


async def usage_summary(
    objective_id: Optional[str] = None,
    model_id: Optional[str] = None,
    workspace_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Aggregate cost and token usage via SurrealQL math functions.
    """
    conditions = []
    params: Dict[str, Any] = {}
    if objective_id:
        conditions.append("objective_id = $oid")
        params["oid"] = objective_id
    if model_id:
        conditions.append("model_id = $mid")
        params["mid"] = model_id
    if workspace_id:
        conditions.append("workspace_id = $wid")
        params["wid"] = workspace_id

    where = f"WHERE {' AND '.join(conditions)}" if conditions else ""

    async with get_db() as db:
        results = await db.query(
            f"""
            SELECT
                count()                    AS total_calls,
                math::sum(input_tokens)    AS total_input_tokens,
                math::sum(output_tokens)   AS total_output_tokens,
                math::sum(cost_usd)        AS total_cost_usd,
                math::mean(cost_usd)       AS avg_cost_per_call
            FROM usage_records
            {where}
            GROUP ALL
            """,
            params,
        )
    rows = _rows(results)
    return rows[0] if rows else {
        "total_calls": 0,
        "total_input_tokens": 0,
        "total_output_tokens": 0,
        "total_cost_usd": 0.0,
        "avg_cost_per_call": 0.0,
    }


async def list_usage_records(
    objective_id: Optional[str] = None,
    limit: int = 100,
) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if objective_id:
            results = await db.query(
                "SELECT * FROM usage_records WHERE objective_id = $oid ORDER BY recorded_at DESC LIMIT $limit",
                {"oid": objective_id, "limit": limit},
            )
        else:
            results = await db.query(
                "SELECT * FROM usage_records ORDER BY recorded_at DESC LIMIT $limit",
                {"limit": limit},
            )
    return [_norm(r) for r in _rows(results)]


# ── Helpers ──────────────────────────────────────────────────────────────────

async def _daily_spend(task_type: str) -> float:
    """Sum of cost_usd for this task_type in the past 24h."""
    async with get_db() as db:
        results = await db.query(
            """
            SELECT math::sum(cost_usd) AS spent
            FROM usage_records
            WHERE recorded_at > time::now() - 1d
            GROUP ALL
            """,
        )
    rows = _rows(results)
    return float(rows[0].get("spent") or 0.0) if rows else 0.0


def _fallback(task_type: str, reason: str) -> Dict[str, Any]:
    return {
        "model_id": "llama3",
        "provider": "ollama",
        "estimated_cost": 0.0,
        "rationale": f"fallback ({reason})",
        "rule_id": None,
    }


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
