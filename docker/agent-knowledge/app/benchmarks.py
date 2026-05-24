"""
M9 Benchmarks — named test suites for regression detection.

A benchmark defines test cases: { topic, kb_ids, artifact_type, min_eval_score }.
Running a benchmark generates an artifact for each case, evaluates it,
and compares the average score against the stored baseline.

Regression: avg_score drops more than regression_threshold (default 0.05)
            below baseline_score.

First run of a benchmark establishes the baseline.
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit
from .generator import generate
from .eval import get_latest_eval


async def create_benchmark(
    name: str,
    artifact_type: str,
    test_cases: List[Dict[str, Any]],
    description: str = "",
    regression_threshold: float = 0.05,
) -> Dict[str, Any]:
    """
    test_cases: list of { topic, kb_ids, instructions?, min_eval_score? }
    """
    async with get_db() as db:
        record = {
            "name": name,
            "description": description,
            "artifact_type": artifact_type,
            "test_cases": test_cases,
            "baseline_score": None,
            "regression_threshold": regression_threshold,
            "created_at": _now(),
        }
        result = await db.create("benchmarks", record)
    return _norm(result[0] if isinstance(result, list) else result)


async def get_benchmark(benchmark_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM benchmarks WHERE id = $id OR name = $id LIMIT 1",
            {"id": benchmark_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def list_benchmarks() -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query("SELECT * FROM benchmarks ORDER BY created_at DESC")
    return [_norm(r) for r in _rows(results)]


async def run_benchmark(
    benchmark_id: str,
    objective_id: str = "benchmark",
    model_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Execute all test cases in the benchmark.
    Compares result against baseline; sets baseline if first run.
    Returns the benchmark_run record.
    """
    bm = await get_benchmark(benchmark_id)
    if not bm:
        raise ValueError(f"Benchmark not found: {benchmark_id}")

    # Create run record
    async with get_db() as db:
        run_record = {
            "benchmark_id": bm["id"],
            "status": "running",
            "case_results": [],
            "model_id": model_id,
            "baseline_score": bm.get("baseline_score"),
            "started_at": _now(),
        }
        res = await db.create("benchmark_runs", run_record)
    run = _norm(res[0] if isinstance(res, list) else res)
    run_id = run["id"]

    await emit("benchmark", run_id, "run_started", {"benchmark": bm["name"]})

    case_results = []
    scores = []

    for case in bm.get("test_cases", []):
        topic = case.get("topic", "")
        kb_ids = case.get("kb_ids", [])
        instructions = case.get("instructions", "")
        min_score = float(case.get("min_eval_score", 0.70))

        try:
            job = await generate(
                objective_id=objective_id,
                artifact_type=bm["artifact_type"],
                kb_ids=kb_ids,
                topic=topic,
                instructions=instructions,
            )
            artifact_id = job.get("artifact_id")
            eval_result = await get_latest_eval(artifact_id) if artifact_id else None
            eval_score = float(eval_result.get("composite_score", 0)) if eval_result else 0.0
            passed = eval_score >= min_score
            scores.append(eval_score)
            case_results.append({
                "topic": topic,
                "artifact_id": artifact_id,
                "eval_score": round(eval_score, 4),
                "min_score": min_score,
                "passed": passed,
            })
        except Exception as exc:
            case_results.append({
                "topic": topic,
                "artifact_id": None,
                "eval_score": 0.0,
                "min_score": min_score,
                "passed": False,
                "error": str(exc),
            })

    avg_score = round(sum(scores) / len(scores), 4) if scores else 0.0
    baseline = bm.get("baseline_score")
    delta = round(avg_score - baseline, 4) if baseline is not None else None
    threshold = float(bm.get("regression_threshold", 0.05))
    regression = (delta is not None and delta < -threshold)
    status = "regressed" if regression else ("passed" if all(c["passed"] for c in case_results) else "failed")

    # Update run
    run_fields = {
        "status": status,
        "case_results": case_results,
        "avg_score": avg_score,
        "delta": delta,
        "regression": regression,
        "completed_at": _now(),
    }
    async with get_db() as db:
        await db.merge(run_id, run_fields)

    # Set baseline on first run
    if baseline is None:
        async with get_db() as db:
            await db.merge(bm["id"], {"baseline_score": avg_score})

    event_payload = {
        "benchmark": bm["name"],
        "avg_score": avg_score,
        "status": status,
        "regression": regression,
    }
    await emit("benchmark", run_id, "run_complete", event_payload)

    run.update(run_fields)
    return run


async def list_runs(benchmark_id: Optional[str] = None) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if benchmark_id:
            results = await db.query(
                "SELECT * FROM benchmark_runs WHERE benchmark_id = $b ORDER BY started_at DESC",
                {"b": benchmark_id},
            )
        else:
            results = await db.query(
                "SELECT * FROM benchmark_runs ORDER BY started_at DESC LIMIT 50"
            )
    return [_norm(r) for r in _rows(results)]


async def get_latest_eval(artifact_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM eval_results WHERE artifact_id = $a ORDER BY evaluated_at DESC LIMIT 1",
            {"a": artifact_id},
        )
    rows = _rows(results)
    return rows[0] if rows else None


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
