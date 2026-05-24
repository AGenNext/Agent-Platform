"""
M9 Analytics — feedback collection, eval trend rollups, routing suggestions.

Feedback loop:
  User rates artifact → artifact_feedback record
  Analytics job rolls up daily eval_trends (score × model × artifact_type)
  Routing analyser reads 7-day trends → proposes weight adjustments

Routing suggestion logic:
  If avg eval_score for a model/task has dropped > 5% vs 14-day baseline
    → suggest reducing accuracy weight or switching preferred model
  If avg latency is 2× the pool average
    → suggest reducing speed weight for that model
  If avg cost is 2× the pool average
    → suggest reducing cost weight
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit


# ── Feedback ──────────────────────────────────────────────────────────────────

async def record_feedback(
    artifact_id: str,
    rating: int,
    dimension_ratings: Optional[Dict[str, int]] = None,
    notes: Optional[str] = None,
    user_id: Optional[str] = None,
    tenant_id: Optional[str] = None,
) -> Dict[str, Any]:
    # Pull artifact metadata to attach model + type to feedback
    async with get_db() as db:
        art_result = await db.query(
            "SELECT objective_id, artifact_type, payload FROM artifacts "
            "WHERE id = $id LIMIT 1",
            {"id": artifact_id},
        )
    art_rows = _rows(art_result)
    art = art_rows[0] if art_rows else {}

    record = {
        "artifact_id": artifact_id,
        "objective_id": art.get("objective_id"),
        "tenant_id": tenant_id,
        "user_id": user_id,
        "rating": max(1, min(5, int(rating))),
        "dimension_ratings": dimension_ratings or {},
        "notes": notes,
        "model_id": (art.get("payload") or {}).get("model"),
        "artifact_type": art.get("artifact_type"),
        "created_at": _now(),
    }
    async with get_db() as db:
        result = await db.create("artifact_feedback", record)
    fb = _norm(result[0] if isinstance(result, list) else result)
    await emit("artifact", artifact_id, "feedback_received", {"rating": rating})
    return fb


async def list_feedback(
    artifact_id: Optional[str] = None,
    tenant_id: Optional[str] = None,
    limit: int = 100,
) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if artifact_id:
            results = await db.query(
                "SELECT * FROM artifact_feedback WHERE artifact_id = $a ORDER BY created_at DESC LIMIT $l",
                {"a": artifact_id, "l": limit},
            )
        elif tenant_id:
            results = await db.query(
                "SELECT * FROM artifact_feedback WHERE tenant_id = $t ORDER BY created_at DESC LIMIT $l",
                {"t": tenant_id, "l": limit},
            )
        else:
            results = await db.query(
                "SELECT * FROM artifact_feedback ORDER BY created_at DESC LIMIT $l",
                {"l": limit},
            )
    return [_norm(r) for r in _rows(results)]


# ── Eval Trend Rollup ─────────────────────────────────────────────────────────

async def compute_trends(days: int = 7) -> List[Dict[str, Any]]:
    """
    Roll up eval_results for the last N days into eval_trends snapshots.
    Groups by (date, artifact_type, model_id).
    """
    async with get_db() as db:
        # Fetch recent eval results joined with artifact metadata
        results = await db.query(
            f"SELECT er.composite_score, er.evaluated_at, "
            f"a.artifact_type, a.payload.model AS model_id "
            f"FROM eval_results AS er "
            f"LEFT JOIN artifacts AS a ON a.id = er.artifact_id "
            f"WHERE er.evaluated_at > time::now() - {days}d "
            f"ORDER BY er.evaluated_at DESC"
        )
    rows = _rows(results)

    # Group by date × artifact_type × model_id
    from collections import defaultdict
    groups: Dict[tuple, List[float]] = defaultdict(list)
    for row in rows:
        ts = (row.get("evaluated_at") or "")[:10]
        atype = row.get("artifact_type") or "unknown"
        model = row.get("model_id") or "unknown"
        score = float(row.get("composite_score") or 0)
        groups[(ts, atype, model)].append(score)

    snapshots = []
    for (date, atype, model), scores in groups.items():
        avg = sum(scores) / len(scores)
        snapshot = {
            "period_date": date,
            "artifact_type": atype,
            "model_id": model,
            "avg_score": round(avg, 4),
            "min_score": round(min(scores), 4),
            "max_score": round(max(scores), 4),
            "sample_count": len(scores),
            "computed_at": _now(),
        }
        # Upsert into eval_trends
        async with get_db() as db:
            existing = await db.query(
                "SELECT id FROM eval_trends WHERE period_date = $d AND artifact_type = $a AND model_id = $m LIMIT 1",
                {"d": date, "a": atype, "m": model},
            )
            ex_rows = _rows(existing)
            if ex_rows:
                await db.merge(str(ex_rows[0]["id"]), snapshot)
            else:
                res = await db.create("eval_trends", snapshot)
                snapshot = _norm(res[0] if isinstance(res, list) else res)
        snapshots.append(snapshot)

    return snapshots


async def list_trends(
    artifact_type: Optional[str] = None,
    model_id: Optional[str] = None,
    days: int = 30,
) -> List[Dict[str, Any]]:
    async with get_db() as db:
        query = "SELECT * FROM eval_trends"
        filters = []
        params: Dict[str, Any] = {}
        if artifact_type:
            filters.append("artifact_type = $at")
            params["at"] = artifact_type
        if model_id:
            filters.append("model_id = $m")
            params["m"] = model_id
        if filters:
            query += " WHERE " + " AND ".join(filters)
        query += " ORDER BY period_date DESC LIMIT $l"
        params["l"] = days * 20  # up to 20 model/type combos per day
        results = await db.query(query, params)
    return [_norm(r) for r in _rows(results)]


# ── Routing Suggestions ───────────────────────────────────────────────────────

_DEFAULT_WEIGHTS = {"speed": 0.25, "cost": 0.40, "accuracy": 0.35}


async def analyse_and_suggest() -> List[Dict[str, Any]]:
    """
    Compare 7-day vs 14-day model performance. Generate routing_suggestions
    when significant drift is detected. Returns newly created suggestions.
    """
    async with get_db() as db:
        perf_result = await db.query(
            "SELECT model_id, task_type, "
            "math::mean(eval_score) AS avg_eval, "
            "math::mean(latency_ms) AS avg_latency, "
            "math::mean(cost_usd) AS avg_cost, "
            "count() AS n "
            "FROM model_performance "
            "WHERE recorded_at > time::now() - 7d AND eval_score != NONE "
            "GROUP BY model_id, task_type"
        )
        baseline_result = await db.query(
            "SELECT model_id, task_type, "
            "math::mean(eval_score) AS avg_eval "
            "FROM model_performance "
            "WHERE recorded_at > time::now() - 14d AND recorded_at <= time::now() - 7d "
            "AND eval_score != NONE "
            "GROUP BY model_id, task_type"
        )
    recent = {(r["model_id"], r["task_type"]): r for r in _rows(perf_result)}
    baseline = {(r["model_id"], r["task_type"]): r for r in _rows(baseline_result)}

    # Pool averages for relative comparison
    all_latencies = [r.get("avg_latency") or 0 for r in recent.values() if r.get("avg_latency")]
    all_costs = [r.get("avg_cost") or 0 for r in recent.values() if r.get("avg_cost")]
    pool_latency = sum(all_latencies) / len(all_latencies) if all_latencies else 1
    pool_cost = sum(all_costs) / len(all_costs) if all_costs else 0.001

    suggestions = []
    for (model_id, task_type), rec in recent.items():
        if rec.get("n", 0) < 3:
            continue  # not enough data

        issues = []
        suggested = dict(_DEFAULT_WEIGHTS)
        current_eval = float(rec.get("avg_eval") or 0)
        base = baseline.get((model_id, task_type))

        # Accuracy regression
        if base:
            base_eval = float(base.get("avg_eval") or 0)
            if base_eval > 0 and (base_eval - current_eval) / base_eval > 0.05:
                issues.append(f"eval_score dropped {round((base_eval - current_eval)*100,1)}% vs 14-day baseline")
                suggested["accuracy"] = max(0.10, suggested["accuracy"] - 0.10)
                suggested["speed"] += 0.05
                suggested["cost"] += 0.05

        # Latency outlier
        avg_lat = float(rec.get("avg_latency") or 0)
        if avg_lat > pool_latency * 2 and avg_lat > 2000:
            issues.append(f"avg latency {round(avg_lat)}ms is 2× pool average")
            suggested["speed"] = max(0.05, suggested["speed"] - 0.10)
            suggested["cost"] += 0.05
            suggested["accuracy"] += 0.05

        # Cost outlier
        avg_cost = float(rec.get("avg_cost") or 0)
        if avg_cost > pool_cost * 2 and avg_cost > 0.01:
            issues.append(f"avg cost ${round(avg_cost,4)} is 2× pool average")
            suggested["cost"] = max(0.05, suggested["cost"] - 0.10)
            suggested["accuracy"] += 0.05
            suggested["speed"] += 0.05

        if not issues:
            continue

        # Normalise weights to sum = 1.0
        total = sum(suggested.values())
        suggested = {k: round(v / total, 3) for k, v in suggested.items()}

        suggestion = {
            "task_type": task_type,
            "current_weights": _DEFAULT_WEIGHTS,
            "suggested_weights": suggested,
            "rationale": f"Model {model_id}: " + "; ".join(issues),
            "evidence": {
                "model_id": model_id,
                "avg_eval_score": round(current_eval, 4),
                "avg_latency_ms": round(avg_lat),
                "avg_cost_usd": round(avg_cost, 6),
                "sample_count": rec.get("n", 0),
            },
            "status": "pending",
            "created_at": _now(),
        }
        async with get_db() as db:
            res = await db.create("routing_suggestions", suggestion)
        suggestions.append(_norm(res[0] if isinstance(res, list) else res))

    await emit("platform", "analytics", "suggestions_generated", {"count": len(suggestions)})
    return suggestions


async def list_suggestions(status: Optional[str] = None) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if status:
            results = await db.query(
                "SELECT * FROM routing_suggestions WHERE status = $s ORDER BY created_at DESC",
                {"s": status},
            )
        else:
            results = await db.query(
                "SELECT * FROM routing_suggestions ORDER BY created_at DESC LIMIT 50"
            )
    return [_norm(r) for r in _rows(results)]


async def resolve_suggestion(suggestion_id: str, action: str) -> Optional[Dict[str, Any]]:
    """action: 'applied' | 'dismissed'"""
    if action not in ("applied", "dismissed"):
        return None
    async with get_db() as db:
        await db.merge(suggestion_id, {"status": action, "resolved_at": _now()})
        results = await db.query(
            "SELECT * FROM routing_suggestions WHERE id = $id LIMIT 1",
            {"id": suggestion_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


# ── Helpers ───────────────────────────────────────────────────────────────────

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
