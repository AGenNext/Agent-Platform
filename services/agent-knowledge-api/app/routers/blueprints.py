from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/blueprints", tags=["blueprints"])


class BlueprintRecord(BaseModel):
    id: str
    blueprint_id: str
    name: str
    description: str | None = None
    goal_types: list[str]
    skill_ids: list[str]
    capabilities: dict[str, bool]
    cost_limit_usd: float
    graph_node: str | None = None
    version: str
    active: bool


@router.get("/", response_model=list[BlueprintRecord])
async def list_blueprints(active: bool = True):
    try:
        results = await db.query(
            "SELECT * FROM blueprint WHERE active = $active ORDER BY name ASC",
            {"active": active},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [_to_record(r) for r in rows]


@router.get("/{blueprint_id}", response_model=BlueprintRecord)
async def get_blueprint(blueprint_id: str):
    try:
        results = await db.query(
            "SELECT * FROM blueprint WHERE blueprint_id = $id LIMIT 1",
            {"id": blueprint_id},
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    if not rows:
        raise HTTPException(status_code=404, detail="Blueprint not found")
    return _to_record(rows[0])


def _to_record(r: dict) -> BlueprintRecord:
    return BlueprintRecord(
        id=str(r.get("id", "")),
        blueprint_id=r.get("blueprint_id", ""),
        name=r.get("name", ""),
        description=r.get("description"),
        goal_types=r.get("goal_types", []),
        skill_ids=r.get("skill_ids", []),
        capabilities=r.get("capabilities", {}),
        cost_limit_usd=float(r.get("cost_limit_usd", 1.0)),
        graph_node=r.get("graph_node"),
        version=r.get("version", "0.1.0"),
        active=bool(r.get("active", True)),
    )
