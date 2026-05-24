"""
Agent-Maturity — objective maturity scoring backed by SurrealDB.

Maturity levels:
  initial     (0.00–0.39) — objective exists, no quality signal yet
  developing  (0.40–0.59) — some artifacts produced but gates not cleared
  capable     (0.60–0.79) — eval or trust gate cleared
  optimising  (0.80–1.00) — both eval and trust cleared, provenance recorded

Gates (each contributes equally):
  has_artifacts      — at least one artifact linked to the objective
  eval_passed        — most recent eval composite >= threshold
  trust_passed       — most recent trust score >= threshold
  has_provenance     — at least one trust_score record with evidence
  objective_healthy  — objective status is not 'error' or 'failed'
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit

LEVEL_THRESHOLDS = [
    (0.80, "optimising"),
    (0.60, "capable"),
    (0.40, "developing"),
    (0.00, "initial"),
]


async def assess_maturity(objective_id: str) -> Dict[str, Any]:
    gates = await _evaluate_gates(objective_id)
    passed = sum(1 for v in gates.values() if v)
    score = round(passed / len(gates), 4)
    level = next(lvl for thresh, lvl in LEVEL_THRESHOLDS if score >= thresh)

    async with get_db() as db:
        result = await db.create("maturity_scores", {
            "objective_id": objective_id,
            "score": score,
            "level": level,
            "gates": gates,
            "assessed_at": _now(),
        })
    record = _norm(result[0] if isinstance(result, list) else result)

    await emit("objective", objective_id, "maturity_assessed", {
        "score": score, "level": level, "gates_passed": passed, "gates_total": len(gates),
    })
    return {**record, "gates": gates}


async def get_maturity(objective_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM maturity_scores WHERE objective_id = $oid ORDER BY assessed_at DESC LIMIT 1",
            {"oid": objective_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def _evaluate_gates(objective_id: str) -> Dict[str, bool]:
    async with get_db() as db:
        # Objective status
        obj_result = await db.query(
            "SELECT status FROM objectives WHERE id = $oid OR string::concat('objectives:', $oid) = string::concat('', id) LIMIT 1",
            {"oid": objective_id},
        )
        obj_rows = _rows(obj_result)
        obj_status = obj_rows[0].get("status", "unknown") if obj_rows else "unknown"

        # Artifacts
        art_result = await db.query(
            "SELECT count() AS n FROM artifacts WHERE objective_id = $oid GROUP ALL",
            {"oid": objective_id},
        )
        art_count = (_rows(art_result) or [{}])[0].get("n", 0)

        # Eval — most recent for any artifact of this objective
        eval_result = await db.query(
            """
            SELECT composite_score, passed FROM eval_results
            WHERE artifact_id INSIDE (
                SELECT string::concat('', id) AS id FROM artifacts WHERE objective_id = $oid
            ).id
            ORDER BY evaluated_at DESC LIMIT 1
            """,
            {"oid": objective_id},
        )
        eval_rows = _rows(eval_result)
        eval_passed = bool(eval_rows and eval_rows[0].get("passed", False))

        # Trust — most recent for any artifact of this objective
        trust_result = await db.query(
            """
            SELECT score, verified FROM trust_scores
            WHERE artifact_id INSIDE (
                SELECT string::concat('', id) AS id FROM artifacts WHERE objective_id = $oid
            ).id
            ORDER BY computed_at DESC LIMIT 1
            """,
            {"oid": objective_id},
        )
        trust_rows = _rows(trust_result)
        trust_score = trust_rows[0].get("score", 0.0) if trust_rows else 0.0
        has_provenance = bool(trust_rows)

    return {
        "has_artifacts":     int(art_count) > 0,
        "eval_passed":       eval_passed,
        "trust_passed":      trust_score >= 0.65,
        "has_provenance":    has_provenance,
        "objective_healthy": obj_status not in ("error", "failed"),
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
