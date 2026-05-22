from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/skills", tags=["skills"])


class SkillRecord(BaseModel):
    id: str
    skill_id: str
    name: str
    category: str


@router.get("/", response_model=list[SkillRecord])
async def list_skills(category: str | None = None):
    vars: dict = {}
    where = ""
    if category:
        where = "WHERE category = $category"
        vars["category"] = category
    try:
        results = await db.query(
            f"SELECT * FROM skill {where} ORDER BY category, name ASC",
            vars,
        )
        rows = results[0].get("result", []) if results else []
    except Exception as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [
        SkillRecord(
            id=str(r.get("id", "")),
            skill_id=r.get("skill_id", ""),
            name=r.get("name", ""),
            category=r.get("category", ""),
        )
        for r in rows
    ]
