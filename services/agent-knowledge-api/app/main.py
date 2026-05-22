from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.db.schema_loader import apply_schemas
from app.db.surrealdb import db
from app.routers import health, objectives


@asynccontextmanager
async def lifespan(app: FastAPI):
    await db.connect()
    applied = await apply_schemas()
    if applied:
        print(f"[startup] Applied schemas: {', '.join(applied)}")
    yield
    await db.close()


app = FastAPI(
    title="Agent Knowledge API",
    version="0.1.0",
    description="Thin orchestration layer over SurrealDB. Data and decisions at same layer.",
    lifespan=lifespan,
)

app.include_router(health.router)
app.include_router(objectives.router)
