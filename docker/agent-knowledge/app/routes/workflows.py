from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..auth import require_api_key

from ..frameworks import (
    create_run, get_run, list_runs, update_run_state,
    complete_run, fail_run,
    save_checkpoint, restore_checkpoint, SurrealDBCheckpointer,
)

router = APIRouter(prefix="/workflows", tags=["agent-frameworks"], dependencies=[Depends(require_api_key)])


class RunCreate(BaseModel):
    objective_id: str
    definition_id: Optional[str] = None
    initial_state: Dict[str, Any] = {}


class StateUpdate(BaseModel):
    state: Dict[str, Any]
    status: Optional[str] = None


class CheckpointSave(BaseModel):
    thread_id: str
    node_id: str
    state: Dict[str, Any]
    metadata: Dict[str, Any] = {}


@router.post("/runs")
async def api_create_run(body: RunCreate):
    return await create_run(body.objective_id, body.definition_id, body.initial_state)


@router.get("/runs/{run_id}")
async def api_get_run(run_id: str):
    run = await get_run(run_id)
    if not run:
        raise HTTPException(404, "Workflow run not found")
    return run


@router.get("/objective/{objective_id}/runs")
async def api_list_runs(objective_id: str):
    return await list_runs(objective_id)


@router.patch("/runs/{run_id}/state")
async def api_update_state(run_id: str, body: StateUpdate):
    return await update_run_state(run_id, body.state, body.status)


@router.post("/runs/{run_id}/complete")
async def api_complete_run(run_id: str, body: StateUpdate):
    return await complete_run(run_id, body.state)


@router.post("/runs/{run_id}/fail")
async def api_fail_run(run_id: str, error: str):
    return await fail_run(run_id, error)


@router.post("/runs/{run_id}/checkpoints")
async def api_save_checkpoint(run_id: str, body: CheckpointSave):
    checkpoint_id = await save_checkpoint(
        run_id, body.thread_id, body.node_id, body.state, body.metadata
    )
    return {"checkpoint_id": checkpoint_id, "run_id": run_id, "thread_id": body.thread_id}


@router.get("/checkpoints/{thread_id}")
async def api_restore_checkpoint(thread_id: str, checkpoint_id: Optional[str] = None):
    result = await restore_checkpoint(thread_id, checkpoint_id)
    if not result:
        raise HTTPException(404, "No checkpoint found for this thread")
    return result


@router.get("/checkpoints/{thread_id}/list")
async def api_list_checkpoints(thread_id: str):
    checkpointer = SurrealDBCheckpointer()
    return await checkpointer.alist({"configurable": {"thread_id": thread_id}})
