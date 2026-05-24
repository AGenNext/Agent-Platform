from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ..model_router import (
    select_model, get_routing_rule, list_routing_rules, upsert_routing_rule,
    record_usage, usage_summary, list_usage_records,
    cost_by_objective, spend_by_model,
)
from ..discovery import run_discovery, list_discovered, get_model
from ..constraints import create_policy, list_policies, delete_policy

router = APIRouter(prefix="/model-router", tags=["model-router"])


class ModelSelectRequest(BaseModel):
    task_type: str
    max_cost_override: Optional[float] = None
    objective_id: Optional[str] = None
    workspace_id: Optional[str] = None
    context_hints: Optional[Dict[str, Any]] = None


class UsageRecord(BaseModel):
    objective_id: str
    model_id: str
    provider: str
    input_tokens: int = 0
    output_tokens: int = 0
    cost_usd: float = 0.0
    workspace_id: Optional[str] = None
    task_type: Optional[str] = None
    latency_ms: Optional[int] = None
    eval_score: Optional[float] = None
    success: bool = True
    error_code: Optional[str] = None


class RoutingRuleUpsert(BaseModel):
    task_type: str
    preferred_provider: str
    models: list = Field(default_factory=list)
    max_cost_per_call: float = 0.10
    daily_budget: float = 10.0
    scoring_weights: Dict[str, float] = Field(
        default_factory=lambda: {"speed": 0.25, "cost": 0.40, "accuracy": 0.35}
    )
    enabled: bool = True


class PolicyCreate(BaseModel):
    policy_type: str
    value: Any
    scope: str = "global"
    target_id: Optional[str] = None
    unit: str = "usd"
    period: str = "daily"


@router.post("/select")
async def api_select_model(body: ModelSelectRequest):
    return await select_model(
        body.task_type, body.max_cost_override,
        body.objective_id, body.workspace_id, body.context_hints,
    )


@router.post("/discover")
async def api_discover():
    return await run_discovery()


@router.get("/models")
async def api_list_models(provider: Optional[str] = None, available_only: bool = True):
    return await list_discovered(provider, available_only)


@router.get("/models/{model_id}")
async def api_get_model(model_id: str, provider: Optional[str] = None):
    m = await get_model(model_id, provider)
    if not m:
        raise HTTPException(404, "Model not found in registry")
    return m


@router.get("/rules")
async def api_list_rules():
    return await list_routing_rules()


@router.get("/rules/{task_type}")
async def api_get_rule(task_type: str):
    return await get_routing_rule(task_type)


@router.put("/rules")
async def api_upsert_rule(body: RoutingRuleUpsert):
    return await upsert_routing_rule(body.model_dump())


@router.get("/constraints")
async def api_list_constraints(scope: Optional[str] = None):
    return await list_policies(scope)


@router.post("/constraints")
async def api_create_constraint(body: PolicyCreate):
    return await create_policy(
        body.policy_type, body.value, body.scope, body.target_id, body.unit, body.period,
    )


@router.delete("/constraints/{policy_id}")
async def api_delete_constraint(policy_id: str):
    await delete_policy(policy_id)
    return {"deleted": policy_id}


@router.post("/usage")
async def api_record_usage(body: UsageRecord):
    return await record_usage(
        body.objective_id, body.model_id, body.provider,
        body.input_tokens, body.output_tokens, body.cost_usd,
        body.workspace_id, body.task_type, body.latency_ms,
        body.eval_score, body.success, body.error_code,
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


@router.get("/usage/by-objective")
async def api_cost_by_objective(limit: int = 20):
    return await cost_by_objective(limit)


@router.get("/usage/by-model")
async def api_spend_by_model(limit: int = 20):
    return await spend_by_model(limit)
