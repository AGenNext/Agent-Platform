from typing import List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..generator import generate, get_job, list_jobs, ARTIFACT_TYPES

router = APIRouter(prefix="/generate", tags=["generator"])


class GenerateRequest(BaseModel):
    objective_id: str
    artifact_type: str
    kb_ids: List[str]
    topic: str
    instructions: Optional[str] = None
    chunk_limit: int = 15


@router.get("/types")
async def api_artifact_types():
    return [{"id": k, "label": v["label"]} for k, v in ARTIFACT_TYPES.items()]


@router.post("")
async def api_generate(body: GenerateRequest):
    if body.artifact_type not in ARTIFACT_TYPES:
        raise HTTPException(400, f"Unknown artifact_type. Choose: {list(ARTIFACT_TYPES)}")
    if not body.kb_ids:
        raise HTTPException(400, "At least one kb_id required")
    try:
        return await generate(
            body.objective_id,
            body.artifact_type,
            body.kb_ids,
            body.topic,
            instructions=body.instructions or "",
            chunk_limit=body.chunk_limit,
        )
    except Exception as exc:
        raise HTTPException(500, str(exc))


@router.get("/jobs/{job_id}")
async def api_get_job(job_id: str):
    job = await get_job(job_id)
    if not job:
        raise HTTPException(404, "Job not found")
    return job


@router.get("/objective/{objective_id}/jobs")
async def api_list_jobs(objective_id: str):
    return await list_jobs(objective_id)
