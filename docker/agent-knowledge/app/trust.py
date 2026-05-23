"""
Agent-Trust — provenance chains and trust scoring backed by SurrealDB.

Each artifact accumulates a provenance chain: ordered list of evidence links
recording (source, extract, agent, step). The trust score is computed from:
    - chain completeness (all steps have sources)
    - source diversity (multiple independent sources)
    - evidence density (number of evidence items vs artifact length proxy)

Score is 0.0–1.0. Verification threshold defaults to 0.65.
"""

import hashlib
import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db

DEFAULT_TRUST_THRESHOLD = 0.65


# ── Provenance ────────────────────────────────────────────────────────────────

async def record_provenance(
    artifact_id: str,
    evidence_links: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Store a provenance chain for an artifact.

    evidence_links: list of {source_ref, extract, agent_id, step_description}
    Returns the trust_score record.
    """
    chain_hash = _hash_chain(evidence_links)
    score = _compute_trust_score(evidence_links)
    verified = score >= DEFAULT_TRUST_THRESHOLD

    async with get_db() as db:
        record = {
            "artifact_id": artifact_id,
            "score": round(score, 4),
            "verified": verified,
            "provenance": evidence_links,
            "verification_method": "chain",
            "chain_hash": chain_hash,
            "computed_at": _now(),
        }
        result = await db.create("trust_scores", record)
        created = _norm(result[0] if isinstance(result, list) else result)

        trust_status = "verified" if verified else "unverified"
        await db.query(
            "UPDATE artifacts SET trust_status = $status WHERE id = $id OR string::concat('artifacts:', $id) = id",
            {"status": trust_status, "id": artifact_id},
        )

    return created


async def get_trust_score(artifact_id: str) -> Optional[Dict[str, Any]]:
    """Return the most recent trust score for an artifact."""
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM trust_scores WHERE artifact_id = $aid ORDER BY computed_at DESC LIMIT 1",
            {"aid": artifact_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def list_trust_scores(artifact_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM trust_scores WHERE artifact_id = $aid ORDER BY computed_at DESC",
            {"aid": artifact_id},
        )
    return [_norm(r) for r in _rows(results)]


async def trust_gate(artifact_id: str, threshold: float = DEFAULT_TRUST_THRESHOLD) -> Dict[str, Any]:
    """
    Check whether the latest trust score passes the threshold.
    Returns {passed, score, verified, threshold}.
    """
    latest = await get_trust_score(artifact_id)
    if not latest:
        return {"passed": False, "score": None, "verified": False, "threshold": threshold, "reason": "no_trust_score"}
    score = latest.get("score", 0.0)
    passed = score >= threshold
    return {
        "passed": passed,
        "score": score,
        "verified": latest.get("verified", False),
        "threshold": threshold,
        "reason": "ok" if passed else "score_below_threshold",
    }


# ── Helpers ──────────────────────────────────────────────────────────────────

def _compute_trust_score(evidence_links: List[Dict[str, Any]]) -> float:
    if not evidence_links:
        return 0.0

    # Completeness: fraction of links with a non-empty source_ref
    complete = sum(1 for e in evidence_links if e.get("source_ref")) / len(evidence_links)

    # Diversity: unique source domains
    sources = {e.get("source_ref", "").split("/")[0] for e in evidence_links if e.get("source_ref")}
    diversity = min(len(sources) / max(len(evidence_links), 1), 1.0)

    # Density: more evidence items = higher confidence (capped at 1.0)
    density = min(len(evidence_links) / 5.0, 1.0)

    return round(complete * 0.5 + diversity * 0.3 + density * 0.2, 4)


def _hash_chain(evidence_links: List[Dict[str, Any]]) -> str:
    payload = json.dumps(evidence_links, sort_keys=True, default=str)
    return hashlib.sha256(payload.encode()).hexdigest()[:16]


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
