from fastapi import APIRouter

from app.db.surrealdb import db

router = APIRouter(tags=["health"])


@router.get("/health")
async def health():
    db_status = "connected" if db.ready else "disconnected"
    return {
        "status": "ok",
        "service": "agent-knowledge-api",
        "version": "0.1.0",
        "db": db_status,
    }
