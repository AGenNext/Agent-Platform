from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..agent_team import (
    create_agent, get_agent, list_agents, update_agent_status,
    create_task, complete_task, list_tasks,
    create_handoff, get_handoff_chain, list_handoffs,
)

router = APIRouter(prefix="/agents", tags=["agent-team"])


class AgentCreate(BaseModel):
    run_id: str
    agent_role: str


class TaskCreate(BaseModel):
    description: str
    skill_id: Optional[str] = None


class TaskComplete(BaseModel):
    output_ref: Optional[str] = None
    status: str = "completed"


class HandoffCreate(BaseModel):
    target_agent_id: str
    context: str = ""
    payload: dict = {}


@router.post("")
async def api_create_agent(body: AgentCreate):
    return await create_agent(body.run_id, body.agent_role)


@router.get("/run/{run_id}")
async def api_list_agents(run_id: str):
    return await list_agents(run_id)


@router.get("/{agent_id}")
async def api_get_agent(agent_id: str):
    agent = await get_agent(agent_id)
    if not agent:
        raise HTTPException(404, "Agent not found")
    return agent


@router.patch("/{agent_id}/status")
async def api_update_status(agent_id: str, status: str):
    return await update_agent_status(agent_id, status)


@router.post("/{agent_id}/tasks")
async def api_create_task(agent_id: str, body: TaskCreate):
    return await create_task(agent_id, body.description, body.skill_id)


@router.get("/{agent_id}/tasks")
async def api_list_tasks(agent_id: str):
    return await list_tasks(agent_id)


@router.patch("/{agent_id}/tasks/{task_id}/complete")
async def api_complete_task(agent_id: str, task_id: str, body: TaskComplete):
    return await complete_task(task_id, body.output_ref, body.status)


@router.post("/{agent_id}/handoff")
async def api_create_handoff(agent_id: str, body: HandoffCreate):
    return await create_handoff(agent_id, body.target_agent_id, body.context, body.payload)


@router.get("/{agent_id}/handoff/chain")
async def api_handoff_chain(agent_id: str):
    return await get_handoff_chain(agent_id)


@router.get("/run/{run_id}/handoffs")
async def api_run_handoffs(run_id: str):
    return await list_handoffs(run_id)
