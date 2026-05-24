from typing import Dict, List, Optional
from fastapi import APIRouter
from pydantic import BaseModel, Field

from ..eval import (
    evaluate_artifact, get_eval_result, list_eval_results, eval_summary,
    CLEAR_DIMENSIONS, DEFAULT_THRESHOLD,
)

router = APIRouter(prefix="/eval", tags=["agent-eval"])


class EvalRequest(BaseModel):
    artifact_id: str
    dimension_scores: Dict[str, float] = Field(
        default_factory=lambda: {d: 0.0 for d in CLEAR_DIMENSIONS}
    )
    rubric_id: Optional[str] = None
    rationale: Optional[str] = None
    weights: Optional[Dict[str, float]] = None
    threshold: float = DEFAULT_THRESHOLD


@router.post("/evaluate")
async def api_evaluate(body: EvalRequest):
    return await evaluate_artifact(
        body.artifact_id,
        body.dimension_scores,
        body.rubric_id,
        body.rationale,
        body.weights,
        body.threshold,
    )


@router.get("/artifacts/{artifact_id}")
async def api_get_eval(artifact_id: str):
    return await get_eval_result(artifact_id)


@router.get("/artifacts/{artifact_id}/history")
async def api_eval_history(artifact_id: str):
    return await list_eval_results(artifact_id)


@router.get("/artifacts/{artifact_id}/summary")
async def api_eval_summary(artifact_id: str):
    return await eval_summary(artifact_id)


@router.get("/dimensions")
def api_dimensions():
    return {"dimensions": CLEAR_DIMENSIONS, "default_threshold": DEFAULT_THRESHOLD}
