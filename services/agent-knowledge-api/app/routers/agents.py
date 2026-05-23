from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.db.surrealdb import db

router = APIRouter(prefix="/agents", tags=["agents"])

REQUIRED_CAPABILITIES = [
    "analytics", "billing", "health", "tracing",
    "auth", "artifacts", "skills", "trust",
]


class AgentRegistration(BaseModel):
    name: str
    description: str | None = None
    version: str = "0.1.0"
    tenant_id: str
    goal_types: list[str] = Field(default_factory=list)
    skill_ids: list[str] = Field(default_factory=list)
    capabilities: dict[str, bool] = Field(
        default_factory=lambda: {c: True for c in REQUIRED_CAPABILITIES}
    )
    model_policy: dict | None = None
    cost_limit_usd: float | None = None
    metadata: dict | None = None


class AgentRecord(BaseModel):
    id: str
    agent_id: str
    name: str
    description: str | None = None
    version: str
    tenant_id: str
    status: str
    capabilities: dict[str, bool]
    goal_types: list[str]
    skill_ids: list[str]
    registered_at: str
    last_seen_at: str


@router.post("/register", status_code=201)
async def register_agent(body: AgentRegistration) -> AgentRecord:
    missing = [c for c in REQUIRED_CAPABILITIES if not body.capabilities.get(c)]
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"Agent missing required capabilities: {missing}. "
                   "Runtime will not assign ID until all capabilities are declared.",
        )

    agent_id = str(uuid4())
    now = datetime.utcnow().isoformat()
    payload = {
        "@context": "https://schema.org",
        "@type": "SoftwareAgent",
        "agent_id": agent_id,
        "name": body.name,
        "description": body.description,
        "version": body.version,
        "tenant_id": body.tenant_id,
        "status": "registered",
        "capabilities": body.capabilities,
        "goal_types": body.goal_types,
        "skill_ids": body.skill_ids,
        "model_policy": body.model_policy,
        "cost_limit_usd": body.cost_limit_usd,
        "metadata": body.metadata,
        "registered_at": now,
        "last_seen_at": now,
    }

    try:
        result = await db.create("agent", payload)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Registry write failed: {exc}") from exc

    record = result[0] if isinstance(result, list) else result
    return AgentRecord(id=str(record.get("id", "")), **{k: record[k] for k in AgentRecord.model_fields if k != "id" and k in record})


@router.get("/", response_model=list[AgentRecord])
async def list_agents(tenant_id: str | None = None, status: str | None = None):
    where_clauses = []
    vars: dict = {}
    if tenant_id:
        where_clauses.append("tenant_id = $tenant_id")
        vars["tenant_id"] = tenant_id
    if status:
        where_clauses.append("status = $status")
        vars["status"] = status

    where = f"WHERE {' AND '.join(where_clauses)}" if where_clauses else ""
    sql = f"SELECT * FROM agent {where} ORDER BY registered_at DESC LIMIT 100"

    try:
        results = await db.query(sql, vars)
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return [
        AgentRecord(id=str(r.get("id", "")), **{k: r[k] for k in AgentRecord.model_fields if k != "id" and k in r})
        for r in rows
    ]


@router.get("/{agent_id}")
async def get_agent(agent_id: str) -> AgentRecord:
    try:
        results = await db.query(
            "SELECT * FROM agent WHERE agent_id = $agent_id LIMIT 1",
            {"agent_id": agent_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    if not rows:
        raise HTTPException(status_code=404, detail="Agent not found in registry")

    r = rows[0]
    return AgentRecord(id=str(r.get("id", "")), **{k: r[k] for k in AgentRecord.model_fields if k != "id" and k in r})


@router.post("/{agent_id}/heartbeat")
async def agent_heartbeat(agent_id: str):
    try:
        await db.query(
            "UPDATE agent SET last_seen_at = $now, status = 'active' WHERE agent_id = $agent_id",
            {"agent_id": agent_id, "now": datetime.utcnow().isoformat()},
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return {"agent_id": agent_id, "status": "active"}
