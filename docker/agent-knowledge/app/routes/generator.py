import asyncio
import json
from typing import List, Optional

from fastapi import APIRouter, BackgroundTasks, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from ..generator import start_generate, generate_background, get_job, list_jobs, ARTIFACT_TYPES

router = APIRouter(prefix="/generate", tags=["generator"])

STEP_LABELS = {
    "pending":             "Queued",
    "running":             "Starting…",
    "retrieving":          "Retrieving knowledge base chunks…",
    "building_context":    "Building context from graph + chunks…",
    "generating":          "Generating with LLM…",
    "recording_provenance":"Recording source provenance…",
    "evaluating":          "Evaluating output…",
    "complete":            "Complete",
    "failed":              "Failed",
}


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
async def api_generate(body: GenerateRequest, background_tasks: BackgroundTasks):
    if body.artifact_type not in ARTIFACT_TYPES:
        raise HTTPException(400, f"Unknown artifact_type. Choose: {list(ARTIFACT_TYPES)}")
    if not body.kb_ids:
        raise HTTPException(400, "At least one kb_id required")
    job = await start_generate(
        body.objective_id,
        body.artifact_type,
        body.kb_ids,
        body.topic,
        instructions=body.instructions or "",
        chunk_limit=body.chunk_limit,
    )
    background_tasks.add_task(generate_background, job["id"], body.chunk_limit)
    return job


@router.get("/jobs/{job_id}")
async def api_get_job(job_id: str):
    job = await get_job(job_id)
    if not job:
        raise HTTPException(404, "Job not found")
    return job


@router.get("/jobs/{job_id}/stream")
async def api_stream_job(job_id: str):
    """
    Server-Sent Events stream that polls job status until complete or failed.
    Each event: data: <JSON>\n\n
    Fields: status, progress_step, step_label, artifact_id, error, done
    """
    async def event_generator():
        last_step = None
        for _ in range(300):  # max 5 min at 1s intervals
            job = await get_job(job_id)
            if not job:
                yield _sse({"error": "Job not found", "done": True})
                return

            step = job.get("progress_step") or job.get("status") or "pending"
            status = job.get("status", "pending")

            if step != last_step:
                last_step = step
                payload = {
                    "status": status,
                    "progress_step": step,
                    "step_label": STEP_LABELS.get(step, step),
                    "artifact_id": job.get("artifact_id"),
                    "model_used": job.get("model_used"),
                    "error": job.get("error"),
                    "done": status in ("complete", "failed"),
                }
                yield _sse(payload)

            if status in ("complete", "failed"):
                return

            await asyncio.sleep(1.0)

        yield _sse({"error": "Stream timeout", "done": True})

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/objective/{objective_id}/jobs")
async def api_list_jobs(objective_id: str):
    return await list_jobs(objective_id)


def _sse(data: dict) -> str:
    return f"data: {json.dumps(data)}\n\n"
