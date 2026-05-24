from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional

from ..maturity import assess_maturity, get_maturity
from ..readiness import compute_readiness, request_approval, submit_approval, get_approval

router = APIRouter(prefix="/maturity", tags=["agent-maturity"])


class ApprovalRequest(BaseModel):
    requested_by: Optional[str] = None


class ApprovalDecision(BaseModel):
    decision: str          # "approved" or "rejected"
    reviewed_by: Optional[str] = None
    notes: Optional[str] = None


@router.post("/objectives/{objective_id}/assess")
async def api_assess(objective_id: str):
    return await assess_maturity(objective_id)


@router.get("/objectives/{objective_id}")
async def api_get_maturity(objective_id: str):
    result = await get_maturity(objective_id)
    return result or {"objective_id": objective_id, "score": 0.0, "level": "initial", "gates": {}}


@router.get("/objectives/{objective_id}/readiness")
async def api_readiness(objective_id: str):
    return await compute_readiness(objective_id)


@router.post("/objectives/{objective_id}/approve/request")
async def api_request_approval(objective_id: str, body: ApprovalRequest):
    snapshot = await compute_readiness(objective_id)
    return await request_approval(objective_id, body.requested_by, snapshot)


@router.post("/objectives/{objective_id}/approve")
async def api_approve(objective_id: str, body: ApprovalDecision):
    return await submit_approval(objective_id, body.decision, body.reviewed_by, body.notes)


@router.get("/objectives/{objective_id}/approval")
async def api_get_approval(objective_id: str):
    result = await get_approval(objective_id)
    return result or {"objective_id": objective_id, "status": "none"}
