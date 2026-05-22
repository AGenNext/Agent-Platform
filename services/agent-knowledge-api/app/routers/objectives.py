from datetime import datetime

from fastapi import APIRouter, HTTPException

from app.db.surrealdb import db
from app.models.objective import (
    ObjectiveRecord,
    ObjectiveRequest,
    ObjectiveResponse,
    ObjectiveStatus,
)

router = APIRouter(prefix="/objectives", tags=["objectives"])


@router.post("/run", response_model=ObjectiveResponse)
async def run_objective(request: ObjectiveRequest):
    record = ObjectiveRecord.from_request(request)
    record.status = ObjectiveStatus.running

    # Store as JSON-LD in SurrealDB — data and decisions at same layer
    jsonld = record.to_jsonld()
    payload = record.model_dump(by_alias=True)
    payload["jsonld"] = jsonld

    try:
        await db.create("objective", payload)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"DB write failed: {exc}") from exc

    # Stub execution — real agent execution replaces this
    record.status = ObjectiveStatus.completed
    record.result = {"message": "Objective accepted", "goal": record.goal}
    record.updated_at = datetime.utcnow()

    try:
        await db.query(
            """
            UPDATE type::thing('objective', $id)
            SET status = $status,
                result = $result,
                updated_at = $updated_at,
                `jsonld.actionStatus` = $status
            """,
            {
                "id": record.id,
                "status": record.status.value,
                "result": record.result,
                "updated_at": record.updated_at.isoformat(),
            },
        )
    except Exception:
        pass

    return ObjectiveResponse(
        objective=record,
        jsonld=record.to_jsonld(),
        message="Objective queued and running",
    )


@router.get("/{objective_id}", response_model=ObjectiveRecord)
async def get_objective(objective_id: str):
    try:
        results = await db.query(
            "SELECT * FROM type::thing('objective', $id)",
            {"id": objective_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"DB query failed: {exc}") from exc

    if not rows:
        raise HTTPException(status_code=404, detail="Objective not found")

    return ObjectiveRecord(**rows[0])


@router.get("/", response_model=list[ObjectiveRecord])
async def list_objectives(limit: int = 50):
    try:
        results = await db.query(
            "SELECT * FROM objective ORDER BY created_at DESC LIMIT $limit",
            {"limit": limit},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"DB query failed: {exc}") from exc

    return [ObjectiveRecord(**r) for r in rows]
