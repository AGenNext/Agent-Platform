import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse

from .db import ping
from .startup import run_startup
from .routes.agents import router as agents_router
from .routes.workflows import router as workflows_router
from .routes.eval import router as eval_router
from .routes.trust import router as trust_router
from .routes.model_router import router as model_router_router
from .routes.events import router as events_router
from .routes.maturity import router as maturity_router
from .routes.knowledge import router as knowledge_router
from .routes.generator import router as generator_router
from .routes.graph import router as graph_router
from .routes.tenants import router as tenants_router
from .routes.analytics import router as analytics_router
from .routes.context_mapper import router as context_mapper_router
from .routes.ingest import router as ingest_router
from .events import emit

# Legacy objective/artifact routes
from .models import ObjectiveCreate, ArtifactCreate, ObjectiveRecord, ArtifactRecord
from typing import List, Optional
from datetime import datetime, timezone
from .db import get_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    await run_startup()
    yield


app = FastAPI(
    title="Agent Knowledge API",
    description="AGenNext source-to-artifact enterprise intelligence API — "
                "Agent-Team, Agent-Frameworks, Eval, Trust, Model-Router all backed by SurrealDB.",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(agents_router)
app.include_router(workflows_router)
app.include_router(eval_router)
app.include_router(trust_router)
app.include_router(model_router_router)
app.include_router(events_router)
app.include_router(maturity_router)
app.include_router(knowledge_router)
app.include_router(generator_router)
app.include_router(graph_router)
app.include_router(tenants_router)
app.include_router(analytics_router)
app.include_router(context_mapper_router)
app.include_router(ingest_router)


# ── Health ───────────────────────────────────────────────────────────────────

@app.get("/health", tags=["platform"])
async def health():
    db_ok = await ping()
    body = {
        "status": "ok" if db_ok else "degraded",
        "service": "agent-knowledge",
        "version": "0.1.0",
        "surrealdb": "connected" if db_ok else "unreachable",
        "env": os.getenv("PLATFORM_ENV", "unknown"),
    }
    return JSONResponse(status_code=200 if db_ok else 503, content=body)


@app.get("/", tags=["platform"])
def root():
    return {
        "service": "agent-knowledge",
        "docs": "/docs",
        "health": "/health",
        "routes": [
            "/agents", "/workflows", "/eval", "/trust",
            "/model-router", "/objectives", "/artifacts",
            "/knowledge-bases", "/generate",
        ],
    }


# ── Objectives ───────────────────────────────────────────────────────────────

@app.post("/objectives", response_model=ObjectiveRecord, tags=["objectives"])
async def create_objective(payload: ObjectiveCreate):
    async with get_db() as db:
        record = {
            "title": payload.title,
            "objective_type": payload.objective_type,
            "workspace_id": payload.workspace_id,
            "payload": payload.payload,
            "status": "pending",
            "created_at": _now(),
            "updated_at": _now(),
        }
        result = await db.create("objectives", record)
    obj = _norm(result[0] if isinstance(result, list) else result)
    await emit("objective", obj["id"], "created", {"title": obj["title"], "objective_type": obj.get("objective_type")})
    return obj


@app.get("/objectives", response_model=List[ObjectiveRecord], tags=["objectives"])
async def list_objectives(status: Optional[str] = None, limit: int = 50):
    async with get_db() as db:
        if status:
            results = await db.query(
                "SELECT * FROM objectives WHERE status = $s LIMIT $l",
                {"s": status, "l": limit},
            )
        else:
            results = await db.query("SELECT * FROM objectives LIMIT $l", {"l": limit})
    return [_norm(r) for r in _rows(results)]


@app.get("/objectives/{objective_id}", response_model=ObjectiveRecord, tags=["objectives"])
async def get_objective(objective_id: str):
    async with get_db() as db:
        result = await db.select(f"objectives:{objective_id}")
    if not result:
        from fastapi import HTTPException
        raise HTTPException(404, "Objective not found")
    return _norm(result)


@app.post("/objectives/{objective_id}/run", tags=["objectives"])
async def run_objective(objective_id: str):
    async with get_db() as db:
        await db.merge(f"objectives:{objective_id}", {
            "status": "running",
            "updated_at": _now(),
        })
    await emit("objective", objective_id, "run_triggered", {"status": "running"})
    return {"objective_id": objective_id, "status": "running"}


# ── Artifacts ────────────────────────────────────────────────────────────────

@app.post("/artifacts", response_model=ArtifactRecord, tags=["artifacts"])
async def create_artifact(payload: ArtifactCreate):
    async with get_db() as db:
        record = {
            "objective_id": payload.objective_id,
            "artifact_type": payload.artifact_type,
            "title": payload.title,
            "content_ref": payload.content_ref,
            "payload": payload.payload,
            "status": "draft",
            "created_at": _now(),
        }
        result = await db.create("artifacts", record)
    artifact = _norm(result[0] if isinstance(result, list) else result)
    await emit("artifact", artifact["id"], "created", {
        "title": artifact["title"],
        "artifact_type": artifact.get("artifact_type"),
        "objective_id": artifact.get("objective_id"),
    })
    return artifact


@app.get("/artifacts", response_model=List[ArtifactRecord], tags=["artifacts"])
async def list_artifacts(objective_id: Optional[str] = None, limit: int = 50):
    async with get_db() as db:
        if objective_id:
            results = await db.query(
                "SELECT * FROM artifacts WHERE objective_id = $oid LIMIT $l",
                {"oid": objective_id, "l": limit},
            )
        else:
            results = await db.query("SELECT * FROM artifacts LIMIT $l", {"l": limit})
    return [_norm(r) for r in _rows(results)]


@app.get("/artifacts/{artifact_id}", response_model=ArtifactRecord, tags=["artifacts"])
async def get_artifact(artifact_id: str):
    async with get_db() as db:
        result = await db.select(f"artifacts:{artifact_id}")
    if not result:
        from fastapi import HTTPException
        raise HTTPException(404, "Artifact not found")
    return _norm(result)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _rows(result):
    if not result:
        return []
    if isinstance(result, list) and result and isinstance(result[0], dict):
        return result[0].get("result", result)
    return result if isinstance(result, list) else []


def _norm(record: dict) -> dict:
    if "id" in record:
        record["id"] = str(record["id"])
    return record
