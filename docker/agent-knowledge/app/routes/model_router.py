from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from ..auth import require_api_key

from ..model_router import (
    select_model, get_routing_rule, list_routing_rules, upsert_routing_rule,
    record_usage, usage_summary, list_usage_records,
)

router = APIRouter(prefix="/model-router", tags=["model-router"], dependencies=[Depends(require_api_key)])


class ModelSelectRequest(BaseModel):
    task_type: str
    max_cost_override: Optional[float] = None


class UsageRecord(BaseModel):
    objective_id: str
    model_id: str
    provider: str
    input_tokens: int = 0
    output_tokens: int = 0
    cost_usd: float = 0.0
    workspace_id: Optional[str] = None


class RoutingRuleUpsert(BaseModel):
    task_type: str
    preferred_provider: str
    models: list = Field(default_factory=list)
    max_cost_per_call: float = 0.10
    daily_budget: float = 10.0
    enabled: bool = True


@router.post("/select")
async def api_select_model(body: ModelSelectRequest):
    return await select_model(body.task_type, body.max_cost_override)


@router.get("/rules")
async def api_list_rules():
    return await list_routing_rules()


@router.get("/rules/{task_type}")
async def api_get_rule(task_type: str):
    return await get_routing_rule(task_type)


@router.put("/rules")
async def api_upsert_rule(body: RoutingRuleUpsert):
    return await upsert_routing_rule(body.model_dump())


@router.post("/usage")
async def api_record_usage(body: UsageRecord):
    return await record_usage(
        body.objective_id, body.model_id, body.provider,
        body.input_tokens, body.output_tokens, body.cost_usd, body.workspace_id,
    )


@router.get("/usage/summary")
async def api_usage_summary(
    objective_id: Optional[str] = None,
    model_id: Optional[str] = None,
    workspace_id: Optional[str] = None,
):
    return await usage_summary(objective_id, model_id, workspace_id)


@router.get("/usage/records")
async def api_usage_records(objective_id: Optional[str] = None, limit: int = 100):
    return await list_usage_records(objective_id, limit)
