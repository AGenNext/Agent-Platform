"""
Release readiness — aggregates eval, trust, maturity, provenance, and approval
into a single gate verdict for an objective.

Source grounding is a hard gate: every artifact must have at least one
evidence link with a non-empty source_ref before the objective can be
marked ready for release.
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit

READINESS_GATES = [
    "has_artifacts",
    "eval_passed",
    "trust_passed",
    "source_grounded",   # hard gate — provenance with source_refs
    "maturity_capable",  # level >= capable (score >= 0.60)
    "approved",
]

HARD_GATES = {"source_grounded", "approved"}


async def compute_readiness(objective_id: str) -> Dict[str, Any]:
    gates = await _check_gates(objective_id)

    hard_blocked = [g for g in HARD_GATES if not gates[g]]
    soft_passed = sum(1 for k, v in gates.items() if k not in HARD_GATES and v)
    soft_total = len(gates) - len(HARD_GATES)

    score = round(soft_passed / soft_total, 4) if soft_total else 0.0
    ready = not hard_blocked and score >= 0.60

    result = {
        "objective_id": objective_id,
        "ready": ready,
        "score": score,
        "gates": gates,
        "hard_blocked": hard_blocked,
        "computed_at": _now(),
    }
    await emit("objective", objective_id, "readiness_computed", {
        "ready": ready, "score": score, "hard_blocked": hard_blocked,
    })
    return result


async def request_approval(
    objective_id: str,
    requested_by: Optional[str] = None,
    readiness_snapshot: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    async with get_db() as db:
        result = await db.create("approvals", {
            "objective_id": objective_id,
            "status": "pending",
            "requested_by": requested_by,
            "readiness_snapshot": readiness_snapshot or {},
            "requested_at": _now(),
        })
    record = _norm(result[0] if isinstance(result, list) else result)
    await emit("objective", objective_id, "approval_requested", {"requested_by": requested_by})
    return record


async def submit_approval(
    objective_id: str,
    decision: str,
    reviewed_by: Optional[str] = None,
    notes: Optional[str] = None,
) -> Dict[str, Any]:
    if decision not in ("approved", "rejected"):
        raise ValueError("decision must be 'approved' or 'rejected'")

    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM approvals WHERE objective_id = $oid AND status = 'pending' ORDER BY requested_at DESC LIMIT 1",
            {"oid": objective_id},
        )
        rows = _rows(results)
        if not rows:
            result = await db.create("approvals", {
                "objective_id": objective_id,
                "status": decision,
                "reviewed_by": reviewed_by,
                "notes": notes,
                "requested_at": _now(),
                "reviewed_at": _now(),
            })
            record = _norm(result[0] if isinstance(result, list) else result)
        else:
            approval_id = str(rows[0]["id"])
            await db.query(
                "UPDATE $aid SET status = $status, reviewed_by = $reviewer, notes = $notes, reviewed_at = $ts",
                {"aid": approval_id, "status": decision, "reviewer": reviewed_by, "notes": notes, "ts": _now()},
            )
            record = {**_norm(rows[0]), "status": decision, "reviewed_by": reviewed_by, "notes": notes}

    await emit("objective", objective_id, "approval_decision", {"decision": decision, "reviewed_by": reviewed_by})
    return record


async def get_approval(objective_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM approvals WHERE objective_id = $oid ORDER BY requested_at DESC LIMIT 1",
            {"oid": objective_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def _check_gates(objective_id: str) -> Dict[str, bool]:
    async with get_db() as db:
        # Artifacts
        art_r = await db.query(
            "SELECT count() AS n FROM artifacts WHERE objective_id = $oid GROUP ALL",
            {"oid": objective_id},
        )
        art_count = int((_rows(art_r) or [{}])[0].get("n", 0))

        # Most recent eval for any artifact of this objective
        eval_r = await db.query(
            """
            SELECT passed FROM eval_results
            WHERE artifact_id INSIDE (
                SELECT string::concat('', id) AS id FROM artifacts WHERE objective_id = $oid
            ).id
            ORDER BY evaluated_at DESC LIMIT 1
            """,
            {"oid": objective_id},
        )
        eval_rows = _rows(eval_r)
        eval_passed = bool(eval_rows and eval_rows[0].get("passed", False))

        # Most recent trust score
        trust_r = await db.query(
            """
            SELECT score, provenance FROM trust_scores
            WHERE artifact_id INSIDE (
                SELECT string::concat('', id) AS id FROM artifacts WHERE objective_id = $oid
            ).id
            ORDER BY computed_at DESC LIMIT 1
            """,
            {"oid": objective_id},
        )
        trust_rows = _rows(trust_r)
        trust_score = float(trust_rows[0].get("score", 0.0)) if trust_rows else 0.0

        # Source grounding — at least one evidence link with a non-empty source_ref
        provenance = trust_rows[0].get("provenance", []) if trust_rows else []
        source_grounded = any(
            link.get("source_ref", "").strip()
            for link in (provenance if isinstance(provenance, list) else [])
        )

        # Maturity
        mat_r = await db.query(
            "SELECT score FROM maturity_scores WHERE objective_id = $oid ORDER BY assessed_at DESC LIMIT 1",
            {"oid": objective_id},
        )
        mat_rows = _rows(mat_r)
        mat_score = float(mat_rows[0].get("score", 0.0)) if mat_rows else 0.0

        # Approval
        appr_r = await db.query(
            "SELECT status FROM approvals WHERE objective_id = $oid ORDER BY requested_at DESC LIMIT 1",
            {"oid": objective_id},
        )
        appr_rows = _rows(appr_r)
        approved = appr_rows[0].get("status") == "approved" if appr_rows else False

    return {
        "has_artifacts":   art_count > 0,
        "eval_passed":     eval_passed,
        "trust_passed":    trust_score >= 0.65,
        "source_grounded": source_grounded,
        "maturity_capable": mat_score >= 0.60,
        "approved":        approved,
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
