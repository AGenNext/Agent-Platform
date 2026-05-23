from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/tasks", tags=["tasks"])

VALID_STATUSES = {"pending", "running", "completed", "failed", "skipped"}


class TaskCreate(BaseModel):
    objective_id: str
    name: str | None = None
    description: str | None = None
    agent_id: str | None = None
    input: dict | None = None


class TaskStatus(BaseModel):
    status: str
    output: dict | None = None
    error: str | None = None


class TaskRecord(BaseModel):
    id: str
    objective_id: str
    name: str | None = None
    description: str | None = None
    agent_id: str | None = None
    status: str
    input: dict | None = None
    output: dict | None = None
    error: str | None = None
    created_at: str
    updated_at: str


@router.post("/", status_code=201, response_model=TaskRecord)
async def create_task(body: TaskCreate):
    now = datetime.utcnow().isoformat()
    payload = {
        "@context": "https://schema.org",
        "@type": "Action",
        "objective_id": f"objective:{body.objective_id}",
        "name": body.name,
        "description": body.description,
        "agent_id": body.agent_id,
        "status": "pending",
        "input": body.input,
        "output": None,
        "error": None,
        "created_at": now,
        "updated_at": now,
    }
    try:
        result = await db.create("task", payload)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    r = result[0] if isinstance(result, list) else result
    return _to_record(r)


@router.get("/", response_model=list[TaskRecord])
async def list_tasks(objective_id: str | None = None, agent_id: str | None = None):
    where_parts = []
    vars: dict = {}
    if objective_id:
        where_parts.append("objective_id = type::thing('objective', $objective_id)")
        vars["objective_id"] = objective_id
    if agent_id:
        where_parts.append("agent_id = $agent_id")
        vars["agent_id"] = agent_id
    where = f"WHERE {' AND '.join(where_parts)}" if where_parts else ""
    sql = f"SELECT * FROM task {where} ORDER BY created_at DESC LIMIT 200"
    try:
        results = await db.query(sql, vars)
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_record(r) for r in rows]


@router.get("/{task_id}", response_model=TaskRecord)
async def get_task(task_id: str):
    try:
        results = await db.query(
            "SELECT * FROM type::thing('task', $id)",
            {"id": task_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    if not rows:
        raise HTTPException(status_code=404, detail="Task not found")
    return _to_record(rows[0])


@router.patch("/{task_id}/status", response_model=TaskRecord)
async def update_task_status(task_id: str, body: TaskStatus):
    if body.status not in VALID_STATUSES:
        raise HTTPException(status_code=422, detail=f"Invalid status: {body.status}")
    now = datetime.utcnow().isoformat()
    try:
        await db.query(
            "UPDATE type::thing('task', $id) SET status = $status, output = $output, error = $error, updated_at = $now",
            {"id": task_id, "status": body.status, "output": body.output, "error": body.error, "now": now},
        )
        results = await db.query("SELECT * FROM type::thing('task', $id)", {"id": task_id})
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    if not rows:
        raise HTTPException(status_code=404, detail="Task not found")
    return _to_record(rows[0])


def _to_record(r: dict) -> TaskRecord:
    obj_id = r.get("objective_id", "")
    if hasattr(obj_id, "__str__"):
        obj_id = str(obj_id).removeprefix("objective:")
    return TaskRecord(
        id=str(r.get("id", "")),
        objective_id=obj_id,
        name=r.get("name"),
        description=r.get("description"),
        agent_id=r.get("agent_id"),
        status=r.get("status", "pending"),
        input=r.get("input"),
        output=r.get("output"),
        error=r.get("error"),
        created_at=str(r.get("created_at", "")),
        updated_at=str(r.get("updated_at", "")),
    )
