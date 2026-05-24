"""
Model-Router — intelligent, multi-objective model selection backed by SurrealDB.

Selection algorithm:
  1. Load objective context (type, workspace, environment).
  2. Load all available models from discovered_models registry.
  3. Retrieve historical performance (avg latency, avg eval score, error rate)
     for each candidate from model_performance table.
  4. Score each candidate on three axes, configurable by routing rule:
       speed_score    = 1 / (normalized_avg_latency)
       cost_score     = 1 - (model_cost / pool_max_cost)   [0 = most expensive]
       accuracy_score = avg CLEAR composite from eval history
  5. composite = w_speed * speed + w_cost * cost + w_accuracy * accuracy
  6. Apply constraint policies (budget, allowlist, denylist, token quota).
  7. Return highest-scoring policy-compliant candidate, or fallback.

FinOps:
  Every record_usage() call writes both a usage_records row (internal) and
  a finops_records row (FinOps FOCUS v1.0 aligned) and a model_performance row.
"""

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit

_PLATFORM_ENV = os.getenv("PLATFORM_ENV", "dev")

# Default scoring weights — can be overridden per routing rule
_DEFAULT_WEIGHTS = {"speed": 0.25, "cost": 0.40, "accuracy": 0.35}


# ── Intelligent routing ───────────────────────────────────────────────────────

async def select_model(
    task_type: str,
    max_cost_override: Optional[float] = None,
    objective_id: Optional[str] = None,
    workspace_id: Optional[str] = None,
    context_hints: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Select the best model for task_type using multi-objective scoring.
    Enforces constraints from agent_constraints before returning.
    """
    # 1. Load routing rule for weights and base config
    rule = await get_routing_rule(task_type)
    weights = _DEFAULT_WEIGHTS.copy()
    if rule:
        w = rule.get("scoring_weights", {})
        if w:
            weights.update(w)

    max_cost = max_cost_override or (rule.get("max_cost_per_call", 0.10) if rule else 0.10)
    daily_budget = rule.get("daily_budget", 10.0) if rule else 10.0

    # 2. Budget gate
    consumed = await _daily_spend()
    budget_remaining = daily_budget - consumed
    if consumed >= daily_budget:
        return _fallback(task_type, f"daily_budget_exhausted (${consumed:.4f} >= ${daily_budget})")

    # 3. Load available models from registry
    candidates = await _load_candidates(task_type, max_cost, rule)
    if not candidates:
        return _fallback(task_type, "no_candidates_discovered")

    # 4. Score each candidate
    pool_max_cost = max(
        (c.get("cost_per_1k_input", 0) + c.get("cost_per_1k_output", 0)) for c in candidates
    ) or 1.0

    scored: List[Dict[str, Any]] = []
    for model in candidates:
        perf = await _model_performance(model["model_id"], task_type)
        score = _composite_score(model, perf, pool_max_cost, weights, context_hints or {})
        scored.append({**model, "_score": score, "_perf": perf})

    scored.sort(key=lambda m: m["_score"], reverse=True)

    # 5. Apply constraint policies — skip violating models
    from .constraints import enforce, PolicyViolation
    for candidate in scored:
        estimated_cost = (
            (candidate.get("cost_per_1k_input", 0) + candidate.get("cost_per_1k_output", 0)) / 1000 * 500
        )  # estimate for ~500 token round-trip
        try:
            await enforce(
                model_id=candidate["model_id"],
                provider=candidate["provider"],
                estimated_cost=estimated_cost,
                task_type=task_type,
                objective_id=objective_id,
                workspace_id=workspace_id,
            )
        except PolicyViolation as e:
            await emit("platform", "model-router", "policy_violation", {
                "model_id": candidate["model_id"], "violation": str(e)
            })
            continue

        return {
            "model_id": candidate["model_id"],
            "provider": candidate["provider"],
            "estimated_cost": estimated_cost,
            "score": round(candidate["_score"], 4),
            "score_breakdown": {
                "speed":    round(candidate["_perf"].get("speed_score", 0.5), 4),
                "cost":     round(1 - (candidate.get("cost_per_1k_input", 0) + candidate.get("cost_per_1k_output", 0)) / pool_max_cost, 4),
                "accuracy": round(candidate["_perf"].get("avg_eval_score", 0.5), 4),
            },
            "context": {
                "task_type": task_type,
                "env": _PLATFORM_ENV,
                "budget_remaining": round(budget_remaining, 4),
            },
            "rule_id": rule.get("id") if rule else None,
            "rationale": (
                f"Selected {candidate['model_id']} (score={candidate['_score']:.3f}) "
                f"from {len(scored)} candidates; weights=speed:{weights['speed']},cost:{weights['cost']},accuracy:{weights['accuracy']}"
            ),
        }

    return _fallback(task_type, "all_candidates_blocked_by_policy")


async def _load_candidates(
    task_type: str,
    max_cost: float,
    rule: Optional[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    """
    Load available models from discovered_models.
    If routing rule has a model allowlist, filter to those.
    Filter by max_cost_per_call.
    In dev env, prefer local (ollama) models.
    """
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM discovered_models WHERE is_available = true ORDER BY is_local DESC, model_id"
        )
    all_models = [_norm(r) for r in _rows(results)]

    # Filter by allowlist if rule specifies
    if rule:
        allowed_ids = [m.get("model_id") for m in rule.get("models", [])]
        if allowed_ids:
            all_models = [m for m in all_models if m["model_id"] in allowed_ids]

    # Filter by max cost (cost per 1k tokens, estimate per call)
    filtered = [
        m for m in all_models
        if (m.get("cost_per_1k_input", 0) + m.get("cost_per_1k_output", 0)) / 1000 * 500 <= max_cost
    ]

    # In dev: strongly prefer local models
    if _PLATFORM_ENV == "dev":
        local = [m for m in filtered if m.get("is_local")]
        if local:
            return local

    return filtered or all_models[:5]


def _composite_score(
    model: Dict[str, Any],
    perf: Dict[str, Any],
    pool_max_cost: float,
    weights: Dict[str, float],
    hints: Dict[str, Any],
) -> float:
    # Speed: normalize avg_latency (lower = better). Missing → 0.5 (unknown).
    avg_latency = perf.get("avg_latency_ms", 1000)
    speed = max(0.0, 1.0 - avg_latency / 5000.0)  # 0ms → 1.0, 5000ms → 0.0

    # Cost: local models are free; cloud models normalized against pool max
    model_cost_per_1k = model.get("cost_per_1k_input", 0) + model.get("cost_per_1k_output", 0)
    cost = 1.0 - (model_cost_per_1k / max(pool_max_cost, 0.001))
    if model.get("is_local"):
        cost = 1.0  # free

    # Accuracy: avg CLEAR composite from historical evals; unknown → neutral 0.5
    accuracy = perf.get("avg_eval_score", 0.5)

    # Context boost: if hint says "requires_vision" and model has vision cap
    if hints.get("requires_vision") and model.get("capabilities", {}).get("vision"):
        accuracy = min(accuracy + 0.15, 1.0)
    if hints.get("requires_reasoning") and model.get("capabilities", {}).get("reasoning"):
        accuracy = min(accuracy + 0.15, 1.0)
    if hints.get("cost_sensitive"):
        weights = {**weights, "cost": min(weights["cost"] + 0.2, 1.0)}

    # Error rate penalty
    error_rate = perf.get("error_rate", 0.0)
    reliability = 1.0 - error_rate

    composite = (
        weights["speed"]    * speed    * reliability +
        weights["cost"]     * cost                   +
        weights["accuracy"] * accuracy
    )
    return round(composite, 6)


async def _model_performance(model_id: str, task_type: str) -> Dict[str, Any]:
    """Load recent performance stats from model_performance table."""
    async with get_db() as db:
        results = await db.query(
            """
            SELECT
                math::mean(latency_ms)  AS avg_latency_ms,
                math::mean(eval_score)  AS avg_eval_score,
                count()                 AS total_calls,
                math::sum(if success = false then 1 else 0 end) AS error_count
            FROM model_performance
            WHERE model_id = $mid AND task_type = $tt AND recorded_at > time::now() - 7d
            GROUP ALL
            """,
            {"mid": model_id, "tt": task_type},
        )
    rows = _rows(results)
    if not rows or not rows[0].get("total_calls"):
        return {"avg_latency_ms": 1000, "avg_eval_score": 0.5, "error_rate": 0.0, "speed_score": 0.5}
    r = rows[0]
    total = int(r.get("total_calls") or 1)
    errors = int(r.get("error_count") or 0)
    return {
        "avg_latency_ms": float(r.get("avg_latency_ms") or 1000),
        "avg_eval_score": float(r.get("avg_eval_score") or 0.5),
        "error_rate": errors / total,
        "speed_score": max(0.0, 1.0 - float(r.get("avg_latency_ms") or 1000) / 5000.0),
    }


# ── Routing rules CRUD ────────────────────────────────────────────────────────

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


# ── Usage recording + FinOps FOCUS + performance tracking ────────────────────

async def record_usage(
    objective_id: str,
    model_id: str,
    provider: str,
    input_tokens: int,
    output_tokens: int,
    cost_usd: float,
    workspace_id: Optional[str] = None,
    task_type: Optional[str] = None,
    latency_ms: Optional[int] = None,
    eval_score: Optional[float] = None,
    success: bool = True,
    error_code: Optional[str] = None,
) -> Dict[str, Any]:
    now = _now()
    async with get_db() as db:
        # Internal usage_record
        usage = await db.create("usage_records", {
            "objective_id": objective_id,
            "model_id": model_id,
            "provider": provider,
            "workspace_id": workspace_id,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost_usd": cost_usd,
            "recorded_at": now,
        })

        # FinOps FOCUS v1.0 record — two rows: one for input, one for output tokens
        if input_tokens > 0:
            await db.create("finops_records", {
                "billing_account_id": workspace_id or "default",
                "billing_period_start": now,
                "billing_period_end": now,
                "service_name": provider,
                "service_category": "AI and Machine Learning",
                "sku_id": model_id,
                "usage_type": "input_tokens",
                "usage_quantity": float(input_tokens),
                "usage_unit": "tokens",
                "list_unit_price": 0.0,
                "list_cost": cost_usd * 0.4,
                "effective_cost": cost_usd * 0.4,
                "billed_cost": cost_usd * 0.4,
                "resource_id": objective_id,
                "resource_name": f"objective/{objective_id}",
                "tags": {"objective_id": objective_id, "workspace_id": workspace_id or "", "task_type": task_type or ""},
                "charge_period_start": now,
            })
        if output_tokens > 0:
            await db.create("finops_records", {
                "billing_account_id": workspace_id or "default",
                "billing_period_start": now,
                "billing_period_end": now,
                "service_name": provider,
                "service_category": "AI and Machine Learning",
                "sku_id": model_id,
                "usage_type": "output_tokens",
                "usage_quantity": float(output_tokens),
                "usage_unit": "tokens",
                "list_unit_price": 0.0,
                "list_cost": cost_usd * 0.6,
                "effective_cost": cost_usd * 0.6,
                "billed_cost": cost_usd * 0.6,
                "resource_id": objective_id,
                "resource_name": f"objective/{objective_id}",
                "tags": {"objective_id": objective_id, "workspace_id": workspace_id or "", "task_type": task_type or ""},
                "charge_period_start": now,
            })

        # Performance record for future routing decisions
        await db.create("model_performance", {
            "model_id": model_id,
            "provider": provider,
            "task_type": task_type or "unknown",
            "objective_id": objective_id,
            "latency_ms": latency_ms,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost_usd": cost_usd,
            "eval_score": eval_score,
            "success": success,
            "error_code": error_code,
            "recorded_at": now,
        })

    record = _norm(usage[0] if isinstance(usage, list) else usage)
    await emit("objective", objective_id, "usage_recorded", {
        "model_id": model_id, "provider": provider,
        "cost_usd": cost_usd, "tokens": input_tokens + output_tokens,
    })
    return record


async def usage_summary(
    objective_id: Optional[str] = None,
    model_id: Optional[str] = None,
    workspace_id: Optional[str] = None,
) -> Dict[str, Any]:
    conditions, params = [], {}
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
            FROM usage_records {where} GROUP ALL
            """,
            params,
        )
    rows = _rows(results)
    return rows[0] if rows else {
        "total_calls": 0, "total_input_tokens": 0, "total_output_tokens": 0,
        "total_cost_usd": 0.0, "avg_cost_per_call": 0.0,
    }


async def cost_by_objective(limit: int = 20) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            """
            SELECT objective_id,
                   math::sum(cost_usd)        AS total_cost,
                   math::sum(input_tokens)    AS total_input,
                   math::sum(output_tokens)   AS total_output,
                   count()                    AS calls
            FROM usage_records
            GROUP BY objective_id
            ORDER BY total_cost DESC LIMIT $l
            """,
            {"l": limit},
        )
    return _rows(results)


async def spend_by_model(limit: int = 20) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            """
            SELECT model_id, provider,
                   math::sum(cost_usd)     AS total_cost,
                   count()                 AS calls,
                   math::mean(cost_usd)    AS avg_cost
            FROM usage_records
            GROUP BY model_id, provider
            ORDER BY total_cost DESC LIMIT $l
            """,
            {"l": limit},
        )
    return _rows(results)


async def list_usage_records(
    objective_id: Optional[str] = None,
    limit: int = 100,
) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if objective_id:
            results = await db.query(
                "SELECT * FROM usage_records WHERE objective_id = $oid ORDER BY recorded_at DESC LIMIT $l",
                {"oid": objective_id, "l": limit},
            )
        else:
            results = await db.query(
                "SELECT * FROM usage_records ORDER BY recorded_at DESC LIMIT $l",
                {"l": limit},
            )
    return [_norm(r) for r in _rows(results)]


# ── Helpers ──────────────────────────────────────────────────────────────────

async def _daily_spend() -> float:
    async with get_db() as db:
        results = await db.query(
            "SELECT math::sum(cost_usd) AS spent FROM usage_records "
            "WHERE recorded_at > time::now() - 1d GROUP ALL",
        )
    rows = _rows(results)
    return float(rows[0].get("spent") or 0.0) if rows else 0.0


def _fallback(task_type: str, reason: str) -> Dict[str, Any]:
    return {
        "model_id": "llama3",
        "provider": "ollama",
        "estimated_cost": 0.0,
        "score": 0.0,
        "score_breakdown": {"speed": 0.0, "cost": 1.0, "accuracy": 0.0},
        "context": {"task_type": task_type, "env": _PLATFORM_ENV, "budget_remaining": 0.0},
        "rule_id": None,
        "rationale": f"fallback ({reason})",
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
