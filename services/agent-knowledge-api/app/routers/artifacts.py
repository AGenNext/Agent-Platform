from datetime import datetime

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/artifacts", tags=["artifacts"])


class ArtifactCreate(BaseModel):
    name: str | None = None
    description: str | None = None
    text: str | None = None
    url: str | None = None
    encoding_format: str = "application/json"
    objective_id: str | None = None
    task_id: str | None = None
    schema_type: str = "CreativeWork"


class ArtifactRecord(BaseModel):
    id: str
    name: str | None = None
    description: str | None = None
    text: str | None = None
    url: str | None = None
    encoding_format: str
    objective_id: str | None = None
    task_id: str | None = None
    trust_score: float | None = None
    eval_status: str | None = None
    created_at: str
    updated_at: str


@router.post("/", status_code=201, response_model=ArtifactRecord)
async def create_artifact(body: ArtifactCreate):
    now = datetime.utcnow().isoformat()
    payload = {
        "@context": "https://schema.org",
        "@type": body.schema_type,
        "name": body.name,
        "description": body.description,
        "text": body.text,
        "url": body.url,
        "encodingFormat": body.encoding_format,
        "objective_id": f"objective:{body.objective_id}" if body.objective_id else None,
        "task_id": f"task:{body.task_id}" if body.task_id else None,
        "trust_score": None,
        "eval_status": None,
        "created_at": now,
        "updated_at": now,
    }
    try:
        result = await db.create("artifact", payload)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    r = result[0] if isinstance(result, list) else result
    return _to_record(r)


@router.get("/", response_model=list[ArtifactRecord])
async def list_artifacts(objective_id: str | None = None, eval_status: str | None = None):
    where_parts = []
    vars: dict = {}
    if objective_id:
        where_parts.append("objective_id = type::thing('objective', $objective_id)")
        vars["objective_id"] = objective_id
    if eval_status:
        where_parts.append("eval_status = $eval_status")
        vars["eval_status"] = eval_status
    where = f"WHERE {' AND '.join(where_parts)}" if where_parts else ""
    sql = f"SELECT * FROM artifact {where} ORDER BY created_at DESC LIMIT 100"
    try:
        results = await db.query(sql, vars)
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_record(r) for r in rows]


@router.get("/{artifact_id}", response_model=ArtifactRecord)
async def get_artifact(artifact_id: str):
    try:
        results = await db.query(
            "SELECT * FROM type::thing('artifact', $id)",
            {"id": artifact_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    if not rows:
        raise HTTPException(status_code=404, detail="Artifact not found")
    return _to_record(rows[0])


def _to_record(r: dict) -> ArtifactRecord:
    def strip_prefix(v: object, prefix: str) -> str | None:
        if v is None:
            return None
        s = str(v)
        return s.removeprefix(prefix) if s.startswith(prefix) else s

    return ArtifactRecord(
        id=str(r.get("id", "")),
        name=r.get("name"),
        description=r.get("description"),
        text=r.get("text"),
        url=r.get("url"),
        encoding_format=r.get("encodingFormat", "application/json"),
        objective_id=strip_prefix(r.get("objective_id"), "objective:"),
        task_id=strip_prefix(r.get("task_id"), "task:"),
        trust_score=r.get("trust_score"),
        eval_status=r.get("eval_status"),
        created_at=str(r.get("created_at", "")),
        updated_at=str(r.get("updated_at", "")),
    )
