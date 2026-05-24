"""
Agent-Eval — CLEAR scoring and quality gates backed by SurrealDB.

CLEAR dimensions:
    Completeness  — does the artifact address all required output fields?
    Logical       — is the reasoning coherent and internally consistent?
    Evidence      — are claims backed by traceable sources?
    Accuracy      — does content match the source material?
    Relevance     — is output aligned with the stated objective?

Each dimension is scored 0.0–1.0. Composite = weighted average.
Gate threshold defaults to 0.70 composite.
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db

CLEAR_DIMENSIONS = ["completeness", "logical", "evidence", "accuracy", "relevance"]
DEFAULT_WEIGHTS = {d: 0.20 for d in CLEAR_DIMENSIONS}
DEFAULT_THRESHOLD = 0.70


# ── Evaluate ─────────────────────────────────────────────────────────────────

async def evaluate_artifact(
    artifact_id: str,
    dimension_scores: Dict[str, float],
    rubric_id: Optional[str] = None,
    rationale: Optional[str] = None,
    weights: Optional[Dict[str, float]] = None,
    threshold: float = DEFAULT_THRESHOLD,
) -> Dict[str, Any]:
    """
    Score an artifact across CLEAR dimensions and persist the result.
    Returns the eval record with passed=True/False.
    """
    w = weights or DEFAULT_WEIGHTS
    composite = sum(
        dimension_scores.get(dim, 0.0) * w.get(dim, 0.20)
        for dim in CLEAR_DIMENSIONS
    )
    passed = composite >= threshold

    scores_list = [
        {"dimension": dim, "score": dimension_scores.get(dim, 0.0), "weight": w.get(dim, 0.20)}
        for dim in CLEAR_DIMENSIONS
    ]

    async with get_db() as db:
        record = {
            "artifact_id": artifact_id,
            "rubric_id": rubric_id,
            "composite_score": round(composite, 4),
            "dimension_scores": scores_list,
            "passed": passed,
            "rationale": rationale,
            "evaluated_at": _now(),
        }
        result = await db.create("eval_results", record)
        created = _norm(result[0] if isinstance(result, list) else result)

        # Update artifact with eval_status
        eval_status = "passed" if passed else "failed"
        await db.query(
            "UPDATE artifacts SET eval_status = $status WHERE id = $id OR string::concat('artifacts:', $id) = id",
            {"status": eval_status, "id": artifact_id},
        )

    return {**created, "threshold": threshold}


async def get_eval_result(artifact_id: str) -> Optional[Dict[str, Any]]:
    """Return the most recent eval result for an artifact."""
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM eval_results WHERE artifact_id = $aid ORDER BY evaluated_at DESC LIMIT 1",
            {"aid": artifact_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def list_eval_results(artifact_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM eval_results WHERE artifact_id = $aid ORDER BY evaluated_at DESC",
            {"aid": artifact_id},
        )
    return [_norm(r) for r in _rows(results)]


async def eval_summary(artifact_id: str) -> Dict[str, Any]:
    """Aggregate eval stats across all runs for an artifact."""
    async with get_db() as db:
        results = await db.query(
            """
            SELECT
                count()           AS total_evals,
                math::mean(composite_score) AS avg_score,
                math::max(composite_score)  AS best_score,
                array::len(array::filter(dimension_scores, |$x| $x.passed = true)) AS passed_count
            FROM eval_results
            WHERE artifact_id = $aid
            GROUP ALL
            """,
            {"aid": artifact_id},
        )
    rows = _rows(results)
    return rows[0] if rows else {"total_evals": 0, "avg_score": None, "best_score": None}


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
