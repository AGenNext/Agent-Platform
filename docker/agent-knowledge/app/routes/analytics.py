from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..analytics import (
    record_feedback, list_feedback,
    compute_trends, list_trends,
    analyse_and_suggest, list_suggestions, resolve_suggestion,
)
from ..benchmarks import (
    create_benchmark, get_benchmark, list_benchmarks,
    run_benchmark, list_runs,
)

router = APIRouter(prefix="/analytics", tags=["analytics"])


# ── Feedback ──────────────────────────────────────────────────────────────────

class FeedbackCreate(BaseModel):
    rating: int                          # 1–5
    dimension_ratings: Dict[str, int] = {}
    notes: Optional[str] = None
    user_id: Optional[str] = None
    tenant_id: Optional[str] = None


@router.post("/feedback/{artifact_id}", status_code=201)
async def api_record_feedback(artifact_id: str, body: FeedbackCreate):
    return await record_feedback(
        artifact_id, body.rating, body.dimension_ratings,
        body.notes, body.user_id, body.tenant_id,
    )


@router.get("/feedback")
async def api_list_feedback(
    artifact_id: Optional[str] = None,
    tenant_id: Optional[str] = None,
    limit: int = 100,
):
    return await list_feedback(artifact_id, tenant_id, min(limit, 500))


# ── Eval Trends ───────────────────────────────────────────────────────────────

@router.post("/trends/compute")
async def api_compute_trends(days: int = 7):
    return await compute_trends(days)


@router.get("/trends")
async def api_list_trends(
    artifact_type: Optional[str] = None,
    model_id: Optional[str] = None,
    days: int = 30,
):
    return await list_trends(artifact_type, model_id, days)


# ── Routing Suggestions ───────────────────────────────────────────────────────

@router.post("/suggestions/analyse")
async def api_analyse():
    return await analyse_and_suggest()


@router.get("/suggestions")
async def api_list_suggestions(status: Optional[str] = None):
    return await list_suggestions(status)


@router.post("/suggestions/{suggestion_id}/resolve")
async def api_resolve_suggestion(suggestion_id: str, action: str):
    result = await resolve_suggestion(suggestion_id, action)
    if not result:
        raise HTTPException(400, "action must be 'applied' or 'dismissed'")
    return result


# ── Benchmarks ────────────────────────────────────────────────────────────────

class BenchmarkCreate(BaseModel):
    name: str
    description: str = ""
    artifact_type: str
    test_cases: List[Dict[str, Any]]
    regression_threshold: float = 0.05


class BenchmarkRun(BaseModel):
    objective_id: str = "benchmark"
    model_id: Optional[str] = None


@router.get("/benchmarks")
async def api_list_benchmarks():
    return await list_benchmarks()


@router.post("/benchmarks", status_code=201)
async def api_create_benchmark(body: BenchmarkCreate):
    return await create_benchmark(
        body.name, body.artifact_type, body.test_cases,
        body.description, body.regression_threshold,
    )


@router.get("/benchmarks/{benchmark_id}")
async def api_get_benchmark(benchmark_id: str):
    bm = await get_benchmark(benchmark_id)
    if not bm:
        raise HTTPException(404, "Benchmark not found")
    return bm


@router.post("/benchmarks/{benchmark_id}/run")
async def api_run_benchmark(benchmark_id: str, body: BenchmarkRun):
    try:
        return await run_benchmark(benchmark_id, body.objective_id, body.model_id)
    except ValueError as exc:
        raise HTTPException(404, str(exc))
    except Exception as exc:
        raise HTTPException(500, str(exc))


@router.get("/benchmarks/{benchmark_id}/runs")
async def api_list_runs(benchmark_id: str):
    return await list_runs(benchmark_id)


@router.get("/runs")
async def api_all_runs():
    return await list_runs()
