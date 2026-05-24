from typing import Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/observability", tags=["observability"])


def _s(v: Any) -> Any:
    if hasattr(v, "__str__") and ":" in str(v) and not isinstance(v, (str, int, float, bool)):
        return str(v)
    if isinstance(v, dict):
        return {k: _s(val) for k, val in v.items()}
    if isinstance(v, list):
        return [_s(i) for i in v]
    return v


class MetricCreate(BaseModel):
    name: str
    value: float
    unit: str | None = None
    tenant_id: str | None = None
    agent_id: str | None = None
    model_id: str | None = None
    labels: dict = {}


class LatencyCreate(BaseModel):
    model_id: str
    provider: str | None = None
    tenant_id: str | None = None
    tokens_in: int = 0
    tokens_out: int = 0
    ttft_ms: float | None = None
    total_ms: float = 0.0
    success: bool = True
    error_code: str | None = None


# ─── Metrics ─────────────────────────────────────────────────────────────────

@router.post("/metrics")
async def emit_metric(body: MetricCreate):
    result = await db.query(
        """
        CREATE metric SET
            name        = $name,
            value       = $value,
            unit        = $unit,
            tenant_id   = $tenant_id,
            agent_id    = $agent_id,
            model_id    = $model_id,
            labels      = $labels,
            recorded_at = time::now()
        """,
        {
            "name": body.name,
            "value": body.value,
            "unit": body.unit,
            "tenant_id": body.tenant_id,
            "agent_id": body.agent_id,
            "model_id": body.model_id,
            "labels": body.labels,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to emit metric")
    return _s(rows[0])


@router.get("/metrics")
async def list_metrics(
    name: str | None = None,
    tenant_id: str | None = None,
    agent_id: str | None = None,
    window: str = "1h",
    limit: int = 500,
):
    filters, params = ["recorded_at >= time::now() - $window"], {"window": window, "limit": limit}
    if name:
        filters.append("name = $name")
        params["name"] = name
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if agent_id:
        filters.append("agent_id = $agent_id")
        params["agent_id"] = agent_id
    where = f"WHERE {' AND '.join(filters)}"
    result = await db.query(
        f"SELECT * FROM metric {where} ORDER BY recorded_at DESC LIMIT $limit",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/metrics/buckets")
async def metric_buckets(
    name: str,
    tenant_id: str | None = None,
    window: str = "1h",
    bucket: str = "5m",
):
    filters = ["name = $name", "recorded_at >= time::now() - $window"]
    params: dict = {"name": name, "window": window}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    where = f"WHERE {' AND '.join(filters)}"
    result = await db.query(
        f"""
        SELECT
            time::floor(recorded_at, $bucket) AS bucket,
            math::sum(value)   AS total,
            math::mean(value)  AS avg,
            math::max(value)   AS max,
            math::min(value)   AS min,
            count()            AS count
        FROM metric
        {where}
        GROUP BY time::floor(recorded_at, $bucket)
        ORDER BY bucket ASC
        """,
        {**params, "bucket": bucket},
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/metrics/summary")
async def metrics_summary(tenant_id: str | None = None, window: str = "24h"):
    filters = ["recorded_at >= time::now() - $window"]
    params: dict = {"window": window}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    where = f"WHERE {' AND '.join(filters)}"
    result = await db.query(
        f"""
        SELECT
            name,
            count()            AS count,
            math::sum(value)   AS total,
            math::mean(value)  AS avg,
            math::max(value)   AS max,
            math::min(value)   AS min
        FROM metric
        {where}
        GROUP BY name
        ORDER BY count DESC
        """,
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


# ─── LLM latency ─────────────────────────────────────────────────────────────

@router.post("/latency")
async def record_latency(body: LatencyCreate):
    result = await db.query(
        """
        CREATE llm_latency SET
            model_id    = $model_id,
            provider    = $provider,
            tenant_id   = $tenant_id,
            tokens_in   = $tokens_in,
            tokens_out  = $tokens_out,
            ttft_ms     = $ttft_ms,
            total_ms    = $total_ms,
            success     = $success,
            error_code  = $error_code,
            recorded_at = time::now()
        """,
        body.model_dump(),
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to record latency")
    return _s(rows[0])


@router.get("/latency/p95")
async def latency_p95(
    tenant_id: str | None = None,
    window: str = "24h",
):
    filters = ["recorded_at >= time::now() - $window"]
    params: dict = {"window": window}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    where = f"WHERE {' AND '.join(filters)}"
    result = await db.query(
        f"""
        SELECT
            model_id,
            provider,
            math::median(total_ms)          AS p50_ms,
            math::mean(total_ms)            AS avg_ms,
            math::max(total_ms)             AS max_ms,
            math::mean(ttft_ms)             AS avg_ttft_ms,
            math::sum(tokens_in)            AS total_tokens_in,
            math::sum(tokens_out)           AS total_tokens_out,
            count()                         AS requests,
            count(WHERE success = false)    AS errors
        FROM llm_latency
        {where}
        GROUP BY model_id, provider
        ORDER BY requests DESC
        """,
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


# ─── Live views (read from materialized views) ────────────────────────────────

@router.get("/views/agent-status")
async def view_agent_status(tenant_id: str | None = None):
    filters, params = [], {}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(f"SELECT * FROM view_agent_status_summary {where}", params)
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/views/daily-spend")
async def view_daily_spend(tenant_id: str | None = None, days: int = 30):
    filters, params = [], {"days": days}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(
        f"SELECT * FROM view_daily_spend {where} ORDER BY year DESC, month DESC, day DESC LIMIT $days",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/views/trust-stats")
async def view_trust_stats(agent_id: str | None = None):
    filters, params = [], {}
    if agent_id:
        filters.append("agent_id = $agent_id")
        params["agent_id"] = agent_id
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(f"SELECT * FROM view_trust_stats {where}", params)
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/views/model-leaderboard")
async def view_model_leaderboard(limit: int = 10):
    result = await db.query(
        "SELECT * FROM view_model_cost_leaderboard ORDER BY total_spend_usd DESC LIMIT $limit",
        {"limit": limit},
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]
