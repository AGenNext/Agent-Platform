from datetime import datetime

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, field_validator

from app.db.surrealdb import db

router = APIRouter(prefix="/trust", tags=["trust"])

VALID_EVAL_STATUSES = {"pending", "passed", "failed", "manual_review"}

# CLEAR evaluation dimensions: Correct, Logical, Evidence-backed, Aligned, Readable
CLEAR_DIMENSIONS = ["correct", "logical", "evidence", "aligned", "readable"]


class ClearEvaluation(BaseModel):
    artifact_id: str
    objective_id: str | None = None
    agent_id: str | None = None
    # Each dimension scored 0.0–1.0
    correct: float = 0.0
    logical: float = 0.0
    evidence: float = 0.0
    aligned: float = 0.0
    readable: float = 0.0
    notes: str | None = None
    reviewer: str | None = None

    @field_validator("correct", "logical", "evidence", "aligned", "readable")
    @classmethod
    def clamp(cls, v: float) -> float:
        return max(0.0, min(1.0, v))


class TrustRecord(BaseModel):
    id: str
    artifact_id: str | None = None
    objective_id: str | None = None
    agent_id: str | None = None
    rating_value: float
    eval_status: str
    evidence: list
    reviewer: str | None = None
    notes: str | None = None
    evaluated_at: str


@router.post("/evaluate", status_code=201, response_model=TrustRecord)
async def evaluate(body: ClearEvaluation):
    # Composite CLEAR score: equal weight across 5 dimensions
    rating_value = (body.correct + body.logical + body.evidence + body.aligned + body.readable) / 5.0
    eval_status = "passed" if rating_value >= 0.7 else "failed"

    evidence = [
        {"dimension": "correct",  "score": body.correct},
        {"dimension": "logical",  "score": body.logical},
        {"dimension": "evidence", "score": body.evidence},
        {"dimension": "aligned",  "score": body.aligned},
        {"dimension": "readable", "score": body.readable},
    ]

    payload = {
        "@context": "https://schema.org",
        "@type": "Rating",
        "name": "trust-evaluation",
        "artifact_id": f"artifact:{body.artifact_id}" if body.artifact_id else None,
        "objective_id": f"objective:{body.objective_id}" if body.objective_id else None,
        "agent_id": body.agent_id,
        "ratingValue": round(rating_value, 4),
        "bestRating": 1.0,
        "worstRating": 0.0,
        "eval_status": eval_status,
        "evidence": evidence,
        "reviewer": body.reviewer,
        "notes": body.notes,
        "evaluated_at": datetime.utcnow().isoformat(),
    }

    try:
        result = await db.create("trust_record", payload)
        # Back-fill trust_score + eval_status onto the artifact
        if body.artifact_id:
            await db.query(
                "UPDATE type::thing('artifact', $id) SET trust_score = $score, eval_status = $status, updated_at = $now",
                {"id": body.artifact_id, "score": round(rating_value, 4), "status": eval_status, "now": datetime.utcnow().isoformat()},
            )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    r = result[0] if isinstance(result, list) else result
    return _to_record(r)


@router.get("/artifact/{artifact_id}", response_model=list[TrustRecord])
async def get_trust_for_artifact(artifact_id: str):
    try:
        results = await db.query(
            "SELECT * FROM trust_record WHERE artifact_id = type::thing('artifact', $id) ORDER BY evaluated_at DESC",
            {"id": artifact_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_record(r) for r in rows]


@router.get("/objective/{objective_id}", response_model=list[TrustRecord])
async def get_trust_for_objective(objective_id: str):
    try:
        results = await db.query(
            "SELECT * FROM trust_record WHERE objective_id = type::thing('objective', $id) ORDER BY evaluated_at DESC",
            {"id": objective_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_record(r) for r in rows]


def _to_record(r: dict) -> TrustRecord:
    def strip(v: object, prefix: str) -> str | None:
        if v is None:
            return None
        s = str(v)
        return s.removeprefix(prefix) if s.startswith(prefix) else s

    return TrustRecord(
        id=str(r.get("id", "")),
        artifact_id=strip(r.get("artifact_id"), "artifact:"),
        objective_id=strip(r.get("objective_id"), "objective:"),
        agent_id=r.get("agent_id"),
        rating_value=float(r.get("ratingValue", 0.0)),
        eval_status=r.get("eval_status", "pending"),
        evidence=r.get("evidence", []),
        reviewer=r.get("reviewer"),
        notes=r.get("notes"),
        evaluated_at=str(r.get("evaluated_at", "")),
    )
