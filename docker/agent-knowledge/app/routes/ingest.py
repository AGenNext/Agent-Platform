from typing import List, Optional
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel

from ..ingest import ingest_text, ingest_file, preview_chunks

router = APIRouter(prefix="/knowledge-bases", tags=["ingest"])


class TextIngestRequest(BaseModel):
    text: str
    source_label: str = ""
    source_ref: str = ""
    strategy: str = "paragraph"     # paragraph | fixed | sentence
    chunk_size: int = 800
    chunk_overlap: int = 100


class PreviewRequest(BaseModel):
    text: str
    strategy: str = "paragraph"
    chunk_size: int = 800
    chunk_overlap: int = 100


@router.post("/{kb_id}/ingest/text")
async def api_ingest_text(kb_id: str, body: TextIngestRequest):
    if not body.text.strip():
        raise HTTPException(400, "text is required")
    if body.chunk_size < 50 or body.chunk_size > 8000:
        raise HTTPException(400, "chunk_size must be 50–8000")
    return await ingest_text(
        kb_id,
        body.text,
        body.source_label,
        body.source_ref,
        body.strategy,
        body.chunk_size,
        body.chunk_overlap,
    )


@router.post("/{kb_id}/ingest/file")
async def api_ingest_file(
    kb_id: str,
    file: UploadFile = File(...),
    source_label: str = Form(""),
    strategy: str = Form("paragraph"),
    chunk_size: int = Form(800),
    chunk_overlap: int = Form(100),
):
    if not file.filename:
        raise HTTPException(400, "filename required")
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:  # 5 MB cap
        raise HTTPException(413, "File too large (max 5 MB)")
    return await ingest_file(
        kb_id,
        file.filename,
        content,
        source_label or file.filename,
        strategy,
        chunk_size,
        chunk_overlap,
    )


@router.post("/ingest/preview")
async def api_preview_chunks(body: PreviewRequest):
    if not body.text.strip():
        raise HTTPException(400, "text is required")
    return {"chunks": preview_chunks(body.text, body.strategy, body.chunk_size, body.chunk_overlap)}
