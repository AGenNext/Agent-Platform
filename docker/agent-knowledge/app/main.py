import os
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse

from .db import get_db, ping
from .models import ArtifactCreate, ArtifactRecord, ObjectiveCreate, ObjectiveRecord

app = FastAPI(
    title="Agent Knowledge API",
    description="AGenNext source-to-artifact enterprise intelligence API",
    version="0.1.0",
)


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
    return {"service": "agent-knowledge", "docs": "/docs", "health": "/health"}


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
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        result = await db.create("objectives", record)
    if not result:
        raise HTTPException(status_code=500, detail="Failed to create objective")
    return _normalize(result[0] if isinstance(result, list) else result)


@app.get("/objectives", response_model=List[ObjectiveRecord], tags=["objectives"])
async def list_objectives(status: Optional[str] = None, limit: int = 50):
    async with get_db() as db:
        if status:
            results = await db.query(
                "SELECT * FROM objectives WHERE status = $status LIMIT $limit",
                {"status": status, "limit": limit},
            )
        else:
            results = await db.query(
                "SELECT * FROM objectives LIMIT $limit",
                {"limit": limit},
            )
    rows = results[0]["result"] if results else []
    return [_normalize(r) for r in rows]


@app.get("/objectives/{objective_id}", response_model=ObjectiveRecord, tags=["objectives"])
async def get_objective(objective_id: str):
    async with get_db() as db:
        result = await db.select(f"objectives:{objective_id}")
    if not result:
        raise HTTPException(status_code=404, detail="Objective not found")
    return _normalize(result)


@app.post("/objectives/{objective_id}/run", tags=["objectives"])
async def run_objective(objective_id: str):
    async with get_db() as db:
        result = await db.select(f"objectives:{objective_id}")
        if not result:
            raise HTTPException(status_code=404, detail="Objective not found")
        await db.merge(f"objectives:{objective_id}", {
            "status": "running",
            "updated_at": datetime.now(timezone.utc).isoformat(),
        })
    return {"objective_id": objective_id, "status": "running", "message": "Objective queued for execution"}


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
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        result = await db.create("artifacts", record)
    if not result:
        raise HTTPException(status_code=500, detail="Failed to create artifact")
    return _normalize(result[0] if isinstance(result, list) else result)


@app.get("/artifacts", response_model=List[ArtifactRecord], tags=["artifacts"])
async def list_artifacts(objective_id: Optional[str] = None, limit: int = 50):
    async with get_db() as db:
        if objective_id:
            results = await db.query(
                "SELECT * FROM artifacts WHERE objective_id = $oid LIMIT $limit",
                {"oid": objective_id, "limit": limit},
            )
        else:
            results = await db.query(
                "SELECT * FROM artifacts LIMIT $limit",
                {"limit": limit},
            )
    rows = results[0]["result"] if results else []
    return [_normalize(r) for r in rows]


@app.get("/artifacts/{artifact_id}", response_model=ArtifactRecord, tags=["artifacts"])
async def get_artifact(artifact_id: str):
    async with get_db() as db:
        result = await db.select(f"artifacts:{artifact_id}")
    if not result:
        raise HTTPException(status_code=404, detail="Artifact not found")
    return _normalize(result)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _normalize(record: dict) -> dict:
    if "id" in record and hasattr(record["id"], "__str__"):
        record["id"] = str(record["id"])
    return record
