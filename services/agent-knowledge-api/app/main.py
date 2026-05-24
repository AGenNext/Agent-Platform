from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.db.schema_loader import apply_schemas
from app.db.surrealdb import db
from app.routers import agents, artifacts, billing, blueprints, deployments, health, knowledge, memory, objectives, observability, sessions, skills, tasks, traces, trust, workflow


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
    description=(
        "Thin orchestration layer over SurrealDB. "
        "Data and decisions at same layer. "
        "Schema.org JSON-LD is the graph data model. "
        "SurrealDB is the runtime, context layer, and digital twin backbone."
    ),
    lifespan=lifespan,
)

app.include_router(health.router)
app.include_router(objectives.router)
app.include_router(agents.router)
app.include_router(memory.router)
app.include_router(tasks.router)
app.include_router(artifacts.router)
app.include_router(trust.router)
app.include_router(billing.router)
app.include_router(blueprints.router)
app.include_router(skills.router)
app.include_router(workflow.router)
app.include_router(traces.router)
app.include_router(sessions.router)
app.include_router(knowledge.router)
app.include_router(deployments.router)
app.include_router(observability.router)
