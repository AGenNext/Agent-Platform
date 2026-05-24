from typing import Any, Dict, List, Optional
from fastapi import APIRouter
from pydantic import BaseModel

from ..trust import (
    record_provenance, get_trust_score, list_trust_scores, trust_gate,
    DEFAULT_TRUST_THRESHOLD,
)

router = APIRouter(prefix="/trust", tags=["agent-trust"])


class EvidenceLink(BaseModel):
    source_ref: str
    extract: str = ""
    agent_id: Optional[str] = None
    step_description: str = ""


class ProvenanceRequest(BaseModel):
    artifact_id: str
    evidence_links: List[EvidenceLink]


class TrustGateRequest(BaseModel):
    artifact_id: str
    threshold: float = DEFAULT_TRUST_THRESHOLD


@router.post("/provenance")
async def api_record_provenance(body: ProvenanceRequest):
    links = [e.model_dump() for e in body.evidence_links]
    return await record_provenance(body.artifact_id, links)


@router.get("/artifacts/{artifact_id}")
async def api_get_trust(artifact_id: str):
    return await get_trust_score(artifact_id)


@router.get("/artifacts/{artifact_id}/history")
async def api_trust_history(artifact_id: str):
    return await list_trust_scores(artifact_id)


@router.post("/gate")
async def api_trust_gate(body: TrustGateRequest):
    return await trust_gate(body.artifact_id, body.threshold)
