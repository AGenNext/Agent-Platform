from typing import List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..graph_builder import build_graph, get_graph_stats
from ..graph_search import local_search, global_search, hybrid_search
from ..db import get_db

router = APIRouter(prefix="/knowledge-bases", tags=["graph"])


class GraphSearchRequest(BaseModel):
    query: str
    kb_ids: List[str]
    mode: str = "hybrid"   # local | global | hybrid
    chunk_limit: int = 15


@router.post("/{kb_id}/graph/build")
async def api_build_graph(kb_id: str):
    """Trigger entity/relation extraction + community detection for a KB."""
    try:
        stats = await build_graph(kb_id)
        return stats
    except Exception as exc:
        raise HTTPException(500, str(exc))


@router.get("/{kb_id}/graph")
async def api_graph_stats(kb_id: str):
    return await get_graph_stats(kb_id)


@router.get("/{kb_id}/entities")
async def api_list_entities(kb_id: str, limit: int = 100):
    async with get_db() as db:
        result = await db.query(
            "SELECT * FROM kb_entities WHERE kb_id = $k ORDER BY mention_count DESC LIMIT $l",
            {"k": kb_id, "l": limit},
        )
    rows = result[0].get("result", result) if isinstance(result, list) and result else result
    if not isinstance(rows, list):
        rows = []
    return [_norm(r) for r in rows]


@router.get("/{kb_id}/communities")
async def api_list_communities(kb_id: str):
    async with get_db() as db:
        result = await db.query(
            "SELECT * FROM kb_communities WHERE kb_id = $k ORDER BY entity_count DESC",
            {"k": kb_id},
        )
    rows = result[0].get("result", result) if isinstance(result, list) and result else result
    if not isinstance(rows, list):
        rows = []
    return [_norm(r) for r in rows]


@router.post("/graph/search")
async def api_graph_search(body: GraphSearchRequest):
    try:
        if body.mode == "local":
            return await local_search(body.kb_ids, body.query, chunk_limit=body.chunk_limit)
        elif body.mode == "global":
            return await global_search(body.kb_ids, body.query)
        else:
            return await hybrid_search(body.kb_ids, body.query, chunk_limit=body.chunk_limit)
    except Exception as exc:
        raise HTTPException(500, str(exc))


def _norm(r: dict) -> dict:
    if "id" in r:
        r["id"] = str(r["id"])
    return r
