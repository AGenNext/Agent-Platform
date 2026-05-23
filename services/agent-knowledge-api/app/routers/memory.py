from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.db.surrealdb import db

router = APIRouter(prefix="/memory", tags=["memory"])


class MemoryCreate(BaseModel):
    agent_id: str
    tenant_id: str
    content: str
    summary: str | None = None
    memory_type: str = Field(default="episodic", pattern="^(episodic|semantic|procedural|working)$")
    embedding: list[float] | None = None
    objective_id: str | None = None
    task_id: str | None = None
    artifact_id: str | None = None
    importance: float = Field(default=0.5, ge=0.0, le=1.0)
    tags: list[str] = Field(default_factory=list)


class MemoryRecord(BaseModel):
    id: str
    agent_id: str
    tenant_id: str
    content: str
    summary: str | None = None
    memory_type: str
    importance: float
    tags: list[str]
    access_count: int
    created_at: str


class MemorySearchRequest(BaseModel):
    agent_id: str
    tenant_id: str
    query: str
    memory_type: str | None = None
    limit: int = Field(default=10, ge=1, le=100)
    # For vector search: provide embedding of the query
    query_embedding: list[float] | None = None


@router.post("/", status_code=201, response_model=MemoryRecord)
async def store_memory(body: MemoryCreate) -> MemoryRecord:
    payload = body.model_dump()
    payload["created_at"] = datetime.utcnow().isoformat()
    payload["accessed_at"] = payload["created_at"]
    payload["access_count"] = 0
    payload["@context"] = "https://schema.org"
    payload["@type"] = "MemoryObject"

    try:
        result = await db.create("memory", payload)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    r = result[0] if isinstance(result, list) else result
    return _to_record(r)


@router.post("/search", response_model=list[MemoryRecord])
async def search_memory(body: MemorySearchRequest) -> list[MemoryRecord]:
    vars: dict = {"agent_id": body.agent_id, "tenant_id": body.tenant_id, "limit": body.limit}

    if body.query_embedding:
        # Vector semantic search
        vars["embedding"] = body.query_embedding
        sql = """
            SELECT *, vector::similarity::cosine(embedding, $embedding) AS score
            FROM memory
            WHERE agent_id = $agent_id AND tenant_id = $tenant_id
            ORDER BY score DESC
            LIMIT $limit
        """
    else:
        # Full-text search
        vars["query"] = body.query
        sql = """
            SELECT *, search::score(1) AS score
            FROM memory
            WHERE agent_id = $agent_id
              AND tenant_id = $tenant_id
              AND content @1@ $query
            ORDER BY score DESC
            LIMIT $limit
        """

    if body.memory_type:
        sql = sql.replace("LIMIT $limit", f"AND memory_type = '{body.memory_type}' LIMIT $limit")

    try:
        results = await db.query(sql, vars)
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return [_to_record(r) for r in rows]


@router.get("/{agent_id}", response_model=list[MemoryRecord])
async def get_agent_memories(
    agent_id: str,
    tenant_id: str,
    memory_type: str | None = None,
    limit: int = 20,
) -> list[MemoryRecord]:
    vars: dict = {"agent_id": agent_id, "tenant_id": tenant_id, "limit": limit}
    type_filter = "AND memory_type = $memory_type " if memory_type else ""
    if memory_type:
        vars["memory_type"] = memory_type

    sql = f"""
        SELECT * FROM memory
        WHERE agent_id = $agent_id AND tenant_id = $tenant_id
        {type_filter}
        ORDER BY importance DESC, accessed_at DESC
        LIMIT $limit
    """

    try:
        results = await db.query(sql, vars)
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return [_to_record(r) for r in rows]


def _to_record(r: dict) -> MemoryRecord:
    return MemoryRecord(
        id=str(r.get("id", "")),
        agent_id=r.get("agent_id", ""),
        tenant_id=r.get("tenant_id", ""),
        content=r.get("content", ""),
        summary=r.get("summary"),
        memory_type=r.get("memory_type", "episodic"),
        importance=r.get("importance", 0.5),
        tags=r.get("tags", []),
        access_count=r.get("access_count", 0),
        created_at=str(r.get("created_at", "")),
    )
