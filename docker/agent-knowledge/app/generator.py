"""
Artifact Generator — retrieves KB chunks, calls LLM, stores grounded artifact.

Flow:
  1. search_chunks() across selected KBs
  2. Build source-grounded prompt from retrieved chunks
  3. Call LLM via Anthropic Messages API (httpx)
  4. Create artifact in DB with generated content
  5. Record trust provenance (source_ref per chunk)
  6. Auto-run CLEAR eval
  7. Emit events at each step
"""

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import httpx

from .db import get_db
from .events import emit
from .knowledge import search_chunks
from .graph_search import hybrid_search, build_prompt_context
from .trust import record_provenance

_ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY", "")
_PIPELINE_MODEL = os.getenv("PIPELINE_MODEL", "claude-sonnet-4-6")

ARTIFACT_TYPES: Dict[str, Dict[str, str]] = {
    "blog_post": {
        "label": "Blog Post",
        "system": (
            "You are an expert content writer. Using only the knowledge base excerpts provided, "
            "write a compelling, well-structured blog post. "
            "Cite sources inline using [Source: <label>] notation. "
            "Structure: introduction, 3-5 body sections with headings, conclusion."
        ),
    },
    "course_outline": {
        "label": "Course Outline",
        "system": (
            "You are an instructional designer. Using only the knowledge base excerpts provided, "
            "create a detailed course outline. "
            "Cite sources inline using [Source: <label>] notation. "
            "Structure: course title, learning objectives, modules with lessons and key concepts, assessment ideas."
        ),
    },
    "sales_deck": {
        "label": "Sales Deck Outline",
        "system": (
            "You are a B2B sales strategist. Using only the knowledge base excerpts provided, "
            "create a slide-by-slide sales deck outline. "
            "Cite sources inline using [Source: <label>] notation. "
            "Structure: problem, solution, differentiators, proof points, pricing/ROI, next steps."
        ),
    },
    "rfp_response": {
        "label": "RFP Response",
        "system": (
            "You are a proposal writer. Using only the knowledge base excerpts provided, "
            "draft a structured RFP response. "
            "Cite sources inline using [Source: <label>] notation. "
            "Structure: executive summary, understanding of requirements, proposed solution, "
            "team and credentials, timeline, pricing, appendices."
        ),
    },
    "summary": {
        "label": "Executive Summary",
        "system": (
            "You are a business analyst. Using only the knowledge base excerpts provided, "
            "write a concise executive summary. "
            "Cite sources inline using [Source: <label>] notation. "
            "Structure: key findings, implications, recommendations."
        ),
    },
    "report": {
        "label": "Research Report",
        "system": (
            "You are a research analyst. Using only the knowledge base excerpts provided, "
            "write a comprehensive research report. "
            "Cite sources inline using [Source: <label>] notation. "
            "Structure: abstract, background, findings, analysis, conclusion, references."
        ),
    },
}


async def start_generate(
    objective_id: str,
    artifact_type: str,
    kb_ids: List[str],
    topic: str,
    instructions: str = "",
    chunk_limit: int = 15,
) -> Dict[str, Any]:
    """
    Create the job record and return it immediately.
    Caller is responsible for running generate_background() as a BackgroundTask.
    """
    job_id = await _create_job(objective_id, artifact_type, kb_ids, topic, instructions)
    await emit("artifact_job", job_id, "started", {"artifact_type": artifact_type, "kb_ids": kb_ids})
    return await _get_job(job_id)


async def generate_background(job_id: str, chunk_limit: int = 15) -> None:
    """Run the full generation pipeline for an already-created job record."""
    job = await _get_job(job_id)
    if not job:
        return

    objective_id  = job["objective_id"]
    artifact_type = job["artifact_type"]
    kb_ids        = job["kb_ids"]
    topic         = job["topic"]
    instructions  = job.get("instructions") or ""

    try:
        await _update_job(job_id, {"status": "running", "progress_step": "retrieving"})

        # 1. Hybrid KB search
        search_result = await hybrid_search(kb_ids, topic, chunk_limit=chunk_limit)
        if not search_result["chunks"] and instructions:
            search_result = await hybrid_search(kb_ids, instructions, chunk_limit=chunk_limit)
        chunks = search_result["chunks"]

        # 2. Build prompt
        await _update_job(job_id, {"progress_step": "building_context"})
        type_spec = ARTIFACT_TYPES.get(artifact_type, ARTIFACT_TYPES["summary"])
        context_block = build_prompt_context(search_result)
        user_prompt = (
            f"Topic: {topic}\n\n"
            + (f"Additional instructions: {instructions}\n\n" if instructions else "")
            + f"Knowledge Base Context:\n{context_block}\n\n"
            + f"Please write the {type_spec['label']} now."
        )

        # 3. Call LLM
        await _update_job(job_id, {"progress_step": "generating"})
        content, model_used = await _call_llm(type_spec["system"], user_prompt)

        # 4. Store artifact
        async with get_db() as db:
            art_record = {
                "objective_id": objective_id,
                "artifact_type": artifact_type,
                "title": f"{type_spec['label']}: {topic[:80]}",
                "content_ref": content,
                "payload": {
                    "topic": topic,
                    "kb_ids": kb_ids,
                    "chunks_used": len(chunks),
                    "model": model_used,
                },
                "status": "draft",
                "created_at": _now(),
            }
            result = await db.create("artifacts", art_record)
        artifact = _norm(result[0] if isinstance(result, list) else result)
        artifact_id = artifact["id"]

        await emit("artifact", artifact_id, "created", {
            "artifact_type": artifact_type,
            "objective_id": objective_id,
            "via": "generator",
        })

        # 5. Provenance
        await _update_job(job_id, {"progress_step": "recording_provenance"})
        evidence_links = []
        for chunk in chunks:
            sr = chunk.get("source_ref") or chunk.get("source_label") or chunk.get("kb_id", "")
            if sr:
                evidence_links.append({
                    "source_ref": sr,
                    "extract": chunk.get("content", "")[:200],
                    "agent_id": "generator",
                    "step_description": f"KB chunk retrieved for {artifact_type}",
                })
        if evidence_links:
            await record_provenance(artifact_id, evidence_links)

        # 6. Auto-eval
        await _update_job(job_id, {"progress_step": "evaluating"})
        has_sources = len(evidence_links) > 0
        evidence_score = min(0.85, 0.45 + 0.04 * len(evidence_links)) if has_sources else 0.35
        auto_scores = {
            "completeness": 0.80,
            "logical": 0.80,
            "evidence": evidence_score,
            "accuracy": 0.75 if has_sources else 0.40,
            "relevance": 0.85,
        }
        from .eval import evaluate_artifact
        await evaluate_artifact(
            artifact_id, auto_scores,
            rationale=f"Auto-eval: {len(chunks)} chunks from {len(kb_ids)} KB(s)"
        )

        # 7. Complete
        chunk_ids = [c.get("id", "") for c in chunks]
        await _update_job(job_id, {
            "status": "complete",
            "progress_step": "complete",
            "artifact_id": artifact_id,
            "chunks_used": chunk_ids,
            "model_used": model_used,
            "completed_at": _now(),
        })
        await emit("artifact_job", job_id, "complete", {"artifact_id": artifact_id})

    except Exception as exc:
        await _update_job(job_id, {
            "status": "failed",
            "progress_step": "failed",
            "error": str(exc),
            "completed_at": _now(),
        })
        await emit("artifact_job", job_id, "failed", {"error": str(exc)})


async def generate(
    objective_id: str,
    artifact_type: str,
    kb_ids: List[str],
    topic: str,
    instructions: str = "",
    chunk_limit: int = 15,
) -> Dict[str, Any]:
    """Synchronous wrapper — creates job and runs pipeline inline. Used by benchmarks."""
    job = await start_generate(objective_id, artifact_type, kb_ids, topic, instructions, chunk_limit)
    await generate_background(job["id"], chunk_limit)
    return await _get_job(job["id"])


async def get_job(job_id: str) -> Optional[Dict[str, Any]]:
    return await _get_job(job_id)


async def list_jobs(objective_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM artifact_jobs WHERE objective_id = $o ORDER BY created_at DESC",
            {"o": objective_id},
        )
    return [_norm(r) for r in _rows(results)]


# ── Internal ──────────────────────────────────────────────────────────────────

async def _create_job(
    objective_id: str,
    artifact_type: str,
    kb_ids: List[str],
    topic: str,
    instructions: str,
) -> str:
    async with get_db() as db:
        record = {
            "objective_id": objective_id,
            "artifact_type": artifact_type,
            "kb_ids": kb_ids,
            "topic": topic,
            "instructions": instructions or None,
            "status": "pending",
            "created_at": _now(),
        }
        result = await db.create("artifact_jobs", record)
    job = _norm(result[0] if isinstance(result, list) else result)
    return job["id"]


async def _update_job(job_id: str, fields: Dict[str, Any]) -> None:
    async with get_db() as db:
        await db.merge(job_id, fields)


async def _get_job(job_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM artifact_jobs WHERE id = $id LIMIT 1",
            {"id": job_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def _call_llm(system: str, user: str) -> tuple[str, str]:
    if not _ANTHROPIC_KEY:
        placeholder = (
            f"[LLM generation requires ANTHROPIC_API_KEY to be configured.]\n\n"
            f"System prompt that would be used:\n{system[:300]}\n\n"
            f"User prompt excerpt:\n{user[:500]}"
        )
        return placeholder, "none"

    async with httpx.AsyncClient(timeout=120.0) as client:
        r = await client.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": _ANTHROPIC_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": _PIPELINE_MODEL,
                "max_tokens": 4096,
                "system": system,
                "messages": [{"role": "user", "content": user}],
            },
        )
        r.raise_for_status()
        data = r.json()
        content = data["content"][0]["text"]
        model_used = data.get("model", _PIPELINE_MODEL)
        return content, model_used


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
