from typing import Any
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/knowledge", tags=["knowledge"])


def _s(v: Any) -> Any:
    if hasattr(v, "__str__") and ":" in str(v) and not isinstance(v, (str, int, float, bool)):
        return str(v)
    if isinstance(v, dict):
        return {k: _s(val) for k, val in v.items()}
    if isinstance(v, list):
        return [_s(i) for i in v]
    return v


class KBCreate(BaseModel):
    tenant_id: str
    agent_id: str | None = None
    name: str
    description: str | None = None
    kb_type: str = "documents"
    embed_model: str = "text-embedding-3-small"
    embed_dim: int = 1536
    chunk_size: int = 512
    chunk_overlap: int = 64


class DocumentCreate(BaseModel):
    tenant_id: str
    title: str
    source_url: str | None = None
    source_type: str = "text"
    content: str | None = None
    metadata: dict = {}


class ChunkCreate(BaseModel):
    tenant_id: str
    chunk_index: int
    content: str
    token_count: int = 0
    embedding: list[float] | None = None
    metadata: dict = {}


class ChunkSearch(BaseModel):
    kb_id: str
    query: str
    limit: int = 10
    mode: str = "bm25"  # bm25 | vector | hybrid


# ─── Knowledge Base CRUD ─────────────────────────────────────────────────────

@router.post("/")
async def create_kb(body: KBCreate):
    kb_id = f"kb-{uuid.uuid4().hex[:12]}"
    result = await db.query(
        """
        CREATE knowledge_base SET
            kb_id       = $kb_id,
            tenant_id   = $tenant_id,
            agent_id    = $agent_id,
            name        = $name,
            description = $description,
            kb_type     = $kb_type,
            embed_model = $embed_model,
            embed_dim   = $embed_dim,
            chunk_size  = $chunk_size,
            chunk_overlap = $chunk_overlap
        """,
        {
            "kb_id": kb_id,
            "tenant_id": body.tenant_id,
            "agent_id": body.agent_id,
            "name": body.name,
            "description": body.description,
            "kb_type": body.kb_type,
            "embed_model": body.embed_model,
            "embed_dim": body.embed_dim,
            "chunk_size": body.chunk_size,
            "chunk_overlap": body.chunk_overlap,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to create knowledge base")
    return _s(rows[0])


@router.get("/")
async def list_kbs(tenant_id: str | None = None, agent_id: str | None = None):
    filters, params = [], {}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if agent_id:
        filters.append("agent_id = $agent_id")
        params["agent_id"] = agent_id
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(f"SELECT * FROM knowledge_base {where} ORDER BY created_at DESC", params)
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/{kb_id}")
async def get_kb(kb_id: str):
    result = await db.query(
        "SELECT * FROM knowledge_base WHERE kb_id = $kb_id LIMIT 1",
        {"kb_id": kb_id},
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(404, "Knowledge base not found")
    return _s(rows[0])


@router.delete("/{kb_id}")
async def delete_kb(kb_id: str):
    await db.query("DELETE knowledge_base WHERE kb_id = $kb_id", {"kb_id": kb_id})
    return {"deleted": kb_id}


# ─── Documents ───────────────────────────────────────────────────────────────

@router.post("/{kb_id}/documents")
async def add_document(kb_id: str, body: DocumentCreate):
    # Verify KB exists
    kb = await db.query(
        "SELECT id FROM knowledge_base WHERE kb_id = $kb_id LIMIT 1",
        {"kb_id": kb_id},
    )
    kb_rows = kb[0].get("result", []) if kb else []
    if not kb_rows:
        raise HTTPException(404, "Knowledge base not found")

    doc_id = f"doc-{uuid.uuid4().hex[:12]}"
    import hashlib
    content_hash = hashlib.sha256((body.content or "").encode()).hexdigest() if body.content else None

    result = await db.query(
        """
        CREATE kb_document SET
            doc_id       = $doc_id,
            kb_id        = $kb_ref,
            tenant_id    = $tenant_id,
            title        = $title,
            source_url   = $source_url,
            source_type  = $source_type,
            content      = $content,
            content_hash = $content_hash,
            status       = 'pending',
            metadata     = $metadata
        """,
        {
            "doc_id": doc_id,
            "kb_ref": kb_rows[0]["id"],
            "tenant_id": body.tenant_id,
            "title": body.title,
            "source_url": body.source_url,
            "source_type": body.source_type,
            "content": body.content,
            "content_hash": content_hash,
            "metadata": body.metadata,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to create document")
    return _s(rows[0])


@router.get("/{kb_id}/documents")
async def list_documents(kb_id: str, status: str | None = None):
    params: dict = {"kb_id": kb_id}
    extra = ""
    if status:
        extra = "AND status = $status"
        params["status"] = status
    result = await db.query(
        f"""
        SELECT * FROM kb_document
        WHERE kb_id.kb_id = $kb_id {extra}
        ORDER BY created_at DESC
        """,
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.delete("/{kb_id}/documents/{doc_id}")
async def delete_document(kb_id: str, doc_id: str):
    await db.query("DELETE kb_document WHERE doc_id = $doc_id", {"doc_id": doc_id})
    await db.query("DELETE kb_chunk WHERE doc_id.doc_id = $doc_id", {"doc_id": doc_id})
    return {"deleted": doc_id}


# ─── Chunks ──────────────────────────────────────────────────────────────────

@router.post("/{kb_id}/documents/{doc_id}/chunks")
async def add_chunks(kb_id: str, doc_id: str, chunks: list[ChunkCreate]):
    doc = await db.query(
        "SELECT id, kb_id FROM kb_document WHERE doc_id = $doc_id LIMIT 1",
        {"doc_id": doc_id},
    )
    doc_rows = doc[0].get("result", []) if doc else []
    if not doc_rows:
        raise HTTPException(404, "Document not found")

    created = []
    for c in chunks:
        r = await db.query(
            """
            CREATE kb_chunk SET
                doc_id      = $doc_ref,
                kb_id       = $kb_ref,
                tenant_id   = $tenant_id,
                chunk_index = $chunk_index,
                content     = $content,
                token_count = $token_count,
                embedding   = $embedding,
                metadata    = $metadata
            """,
            {
                "doc_ref": doc_rows[0]["id"],
                "kb_ref": doc_rows[0]["kb_id"],
                "tenant_id": c.tenant_id,
                "chunk_index": c.chunk_index,
                "content": c.content,
                "token_count": c.token_count,
                "embedding": c.embedding,
                "metadata": c.metadata,
            },
        )
        rows = r[0].get("result", []) if r else []
        if rows:
            created.append(_s(rows[0]))

    # Mark document as indexed
    await db.query(
        "UPDATE kb_document SET status = 'indexed', chunk_count = $n, indexed_at = time::now() WHERE doc_id = $doc_id",
        {"doc_id": doc_id, "n": len(created)},
    )
    return {"created": len(created), "chunks": created}


# ─── Search ──────────────────────────────────────────────────────────────────

@router.post("/search")
async def search_chunks(body: ChunkSearch):
    if body.mode == "bm25":
        result = await db.query(
            """
            SELECT content, search::score(1) AS score,
                   doc_id.title AS doc_title
            FROM kb_chunk
            WHERE kb_id.kb_id = $kb_id
              AND content @1@ $query
            ORDER BY score DESC
            LIMIT $limit
            """,
            {"kb_id": body.kb_id, "query": body.query, "limit": body.limit},
        )
    else:
        # Fallback to BM25 when no embedding provided
        result = await db.query(
            """
            SELECT content, search::score(1) AS score,
                   doc_id.title AS doc_title
            FROM kb_chunk
            WHERE kb_id.kb_id = $kb_id
              AND content @1@ $query
            ORDER BY score DESC
            LIMIT $limit
            """,
            {"kb_id": body.kb_id, "query": body.query, "limit": body.limit},
        )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]
