from datetime import datetime

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/billing", tags=["billing"])


class UsageCreate(BaseModel):
    tenant_id: str
    objective_id: str | None = None
    task_id: str | None = None
    model_id: str | None = None
    provider: str | None = None
    tokens_in: int = 0
    tokens_out: int = 0
    cost_usd: float = 0.0
    duration_ms: int | None = None


class UsageRecord(BaseModel):
    id: str
    tenant_id: str
    objective_id: str | None = None
    task_id: str | None = None
    model_id: str | None = None
    provider: str | None = None
    tokens_in: int
    tokens_out: int
    cost_usd: float
    duration_ms: int | None = None
    recorded_at: str


class CostSummary(BaseModel):
    tenant_id: str
    total_spend_usd: float
    total_tokens: int
    total_calls: int
    spend_by_model: list[dict]
    spend_by_objective: list[dict]


@router.post("/usage", status_code=201, response_model=UsageRecord)
async def log_usage(body: UsageCreate):
    payload = {
        "@context": "https://schema.org",
        "@type": "Invoice",
        "tenant_id": body.tenant_id,
        "objective_id": f"objective:{body.objective_id}" if body.objective_id else None,
        "task_id": f"task:{body.task_id}" if body.task_id else None,
        "model_id": body.model_id,
        "provider": body.provider,
        "tokens_in": body.tokens_in,
        "tokens_out": body.tokens_out,
        "cost_usd": body.cost_usd,
        "duration_ms": body.duration_ms,
        "recorded_at": datetime.utcnow().isoformat(),
    }
    try:
        result = await db.create("usage_record", payload)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    r = result[0] if isinstance(result, list) else result
    return _to_usage_record(r)


@router.get("/usage", response_model=list[UsageRecord])
async def list_usage(tenant_id: str, limit: int = 100):
    try:
        results = await db.query(
            "SELECT * FROM usage_record WHERE tenant_id = $tenant_id ORDER BY recorded_at DESC LIMIT $limit",
            {"tenant_id": tenant_id, "limit": limit},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_usage_record(r) for r in rows]


@router.get("/summary", response_model=CostSummary)
async def cost_summary(tenant_id: str):
    try:
        totals_res = await db.query(
            """
            SELECT
                math::sum(cost_usd) AS total_spend_usd,
                math::sum(tokens_in + tokens_out) AS total_tokens,
                count() AS total_calls
            FROM usage_record WHERE tenant_id = $tenant_id
            """,
            {"tenant_id": tenant_id},
        )
        by_model_res = await db.query(
            """
            SELECT model_id, provider,
                math::sum(cost_usd) AS spend_usd,
                count() AS calls
            FROM usage_record WHERE tenant_id = $tenant_id
            GROUP BY model_id, provider
            ORDER BY spend_usd DESC LIMIT 20
            """,
            {"tenant_id": tenant_id},
        )
        by_obj_res = await db.query(
            """
            SELECT objective_id,
                math::sum(cost_usd) AS spend_usd,
                count() AS calls
            FROM usage_record WHERE tenant_id = $tenant_id
            GROUP BY objective_id
            ORDER BY spend_usd DESC LIMIT 20
            """,
            {"tenant_id": tenant_id},
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    totals = (totals_res[0].get("result") or [{}])[0]
    by_model = by_model_res[0].get("result", []) if by_model_res else []
    by_obj = by_obj_res[0].get("result", []) if by_obj_res else []

    return CostSummary(
        tenant_id=tenant_id,
        total_spend_usd=float(totals.get("total_spend_usd") or 0.0),
        total_tokens=int(totals.get("total_tokens") or 0),
        total_calls=int(totals.get("total_calls") or 0),
        spend_by_model=by_model,
        spend_by_objective=by_obj,
    )


def _to_usage_record(r: dict) -> UsageRecord:
    def strip(v: object, prefix: str) -> str | None:
        if v is None:
            return None
        s = str(v)
        return s.removeprefix(prefix) if s.startswith(prefix) else s

    return UsageRecord(
        id=str(r.get("id", "")),
        tenant_id=str(r.get("tenant_id", "")),
        objective_id=strip(r.get("objective_id"), "objective:"),
        task_id=strip(r.get("task_id"), "task:"),
        model_id=r.get("model_id"),
        provider=r.get("provider"),
        tokens_in=int(r.get("tokens_in", 0)),
        tokens_out=int(r.get("tokens_out", 0)),
        cost_usd=float(r.get("cost_usd", 0.0)),
        duration_ms=r.get("duration_ms"),
        recorded_at=str(r.get("recorded_at", "")),
    )
