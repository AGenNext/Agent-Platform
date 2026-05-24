"""
Knowledge Base management — CRUD for KBs and their text chunks.

Chunks are the retrieval unit. Content search uses SurrealDB text matching;
if embeddings are stored, callers can add vector search via MTREE index.
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit


async def list_knowledge_bases(workspace_id: Optional[str] = None) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if workspace_id:
            results = await db.query(
                "SELECT * FROM knowledge_bases WHERE workspace_id = $w ORDER BY name",
                {"w": workspace_id},
            )
        else:
            results = await db.query("SELECT * FROM knowledge_bases ORDER BY name")
    return [_norm(r) for r in _rows(results)]


async def create_knowledge_base(
    name: str,
    description: str = "",
    kb_type: str = "general",
    workspace_id: Optional[str] = None,
) -> Dict[str, Any]:
    async with get_db() as db:
        record = {
            "name": name,
            "description": description,
            "kb_type": kb_type,
            "workspace_id": workspace_id,
            "chunk_count": 0,
            "created_at": _now(),
            "updated_at": _now(),
        }
        result = await db.create("knowledge_bases", record)
    kb = _norm(result[0] if isinstance(result, list) else result)
    await emit("knowledge_base", kb["id"], "created", {"name": name, "kb_type": kb_type})
    return kb


async def get_knowledge_base(kb_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM knowledge_bases WHERE id = $id OR string::concat('knowledge_bases:', $id) = string($id) LIMIT 1",
            {"id": kb_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def delete_knowledge_base(kb_id: str) -> bool:
    async with get_db() as db:
        await db.query("DELETE FROM kb_chunks WHERE kb_id = $k", {"k": kb_id})
        await db.query(
            "DELETE FROM knowledge_bases WHERE id = $id OR string::concat('knowledge_bases:', $id) = string($id)",
            {"id": kb_id},
        )
    return True


async def add_chunk(
    kb_id: str,
    content: str,
    source_ref: Optional[str] = None,
    source_label: Optional[str] = None,
    embedding: Optional[List[float]] = None,
    metadata: Optional[Dict[str, Any]] = None,
    seq: int = 0,
) -> Dict[str, Any]:
    async with get_db() as db:
        record = {
            "kb_id": kb_id,
            "content": content,
            "embedding": embedding,
            "source_ref": source_ref,
            "source_label": source_label or source_ref or "",
            "seq": seq,
            "metadata": metadata or {},
            "created_at": _now(),
        }
        result = await db.create("kb_chunks", record)
        chunk = _norm(result[0] if isinstance(result, list) else result)
        await db.query(
            "UPDATE knowledge_bases SET chunk_count += 1, updated_at = $t WHERE id = $kb OR string::concat('knowledge_bases:', $kb) = string($kb)",
            {"kb": kb_id, "t": _now()},
        )
    return chunk


async def list_chunks(kb_id: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM kb_chunks WHERE kb_id = $k ORDER BY seq, created_at LIMIT $l START $o",
            {"k": kb_id, "l": limit, "o": offset},
        )
    return [_norm(r) for r in _rows(results)]


async def search_chunks(
    kb_ids: List[str],
    query: str,
    limit: int = 20,
) -> List[Dict[str, Any]]:
    """
    Text-based chunk retrieval across one or more KBs.
    Scores each chunk by number of query terms found in content (case-insensitive).
    Returns top-N by score, deduplicated by chunk id.
    """
    if not kb_ids or not query.strip():
        return []

    # Break query into individual terms (min 3 chars to skip noise words)
    terms = [t.lower() for t in query.split() if len(t) >= 3]
    if not terms:
        terms = [query.lower()]

    # Fetch all chunks from selected KBs
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM kb_chunks WHERE kb_id INSIDE $kbs",
            {"kbs": kb_ids},
        )
    chunks = [_norm(r) for r in _rows(results)]

    # Score by term overlap
    scored = []
    for chunk in chunks:
        text = (chunk.get("content") or "").lower()
        score = sum(1 for t in terms if t in text)
        if score > 0:
            scored.append((score, chunk))

    scored.sort(key=lambda x: x[0], reverse=True)
    return [c for _, c in scored[:limit]]


# ── Helpers ──────────────────────────────────────────────────────────────────

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
