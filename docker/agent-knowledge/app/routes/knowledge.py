from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..knowledge import (
    list_knowledge_bases, create_knowledge_base, get_knowledge_base,
    delete_knowledge_base, add_chunk, list_chunks, search_chunks,
)

router = APIRouter(prefix="/knowledge-bases", tags=["knowledge"])


class KBCreate(BaseModel):
    name: str
    description: str = ""
    kb_type: str = "general"
    workspace_id: Optional[str] = None


class ChunkAdd(BaseModel):
    content: str
    source_ref: Optional[str] = None
    source_label: Optional[str] = None
    embedding: Optional[List[float]] = None
    metadata: Dict[str, Any] = {}
    seq: int = 0


class ChunkSearch(BaseModel):
    query: str
    limit: int = 20


@router.get("")
async def api_list_kbs(workspace_id: Optional[str] = None):
    return await list_knowledge_bases(workspace_id)


@router.post("", status_code=201)
async def api_create_kb(body: KBCreate):
    return await create_knowledge_base(
        body.name, body.description, body.kb_type, body.workspace_id
    )


@router.get("/{kb_id}")
async def api_get_kb(kb_id: str):
    kb = await get_knowledge_base(kb_id)
    if not kb:
        raise HTTPException(404, "Knowledge base not found")
    return kb


@router.delete("/{kb_id}", status_code=204)
async def api_delete_kb(kb_id: str):
    await delete_knowledge_base(kb_id)


@router.get("/{kb_id}/chunks")
async def api_list_chunks(kb_id: str, limit: int = 100, offset: int = 0):
    return await list_chunks(kb_id, limit=limit, offset=offset)


@router.post("/{kb_id}/chunks", status_code=201)
async def api_add_chunk(kb_id: str, body: ChunkAdd):
    return await add_chunk(
        kb_id,
        body.content,
        source_ref=body.source_ref,
        source_label=body.source_label,
        embedding=body.embedding,
        metadata=body.metadata,
        seq=body.seq,
    )


@router.post("/{kb_id}/search")
async def api_search_kb(kb_id: str, body: ChunkSearch):
    return await search_chunks([kb_id], body.query, limit=body.limit)
