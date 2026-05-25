from typing import Any
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/rate-limits", tags=["rate-limits"])


def _s(v: Any) -> Any:
    if hasattr(v, "__str__") and ":" in str(v) and not isinstance(v, (str, int, float, bool)):
        return str(v)
    if isinstance(v, dict):
        return {k: _s(val) for k, val in v.items()}
    if isinstance(v, list):
        return [_s(i) for i in v]
    return v


class RateLimitConfig(BaseModel):
    tenant_id: str
    agent_id: str | None = None
    scope: str = "tenant"
    resource: str
    limit: int
    window: str = "1m"
    burst_limit: int | None = None
    active: bool = True


class QuotaCheck(BaseModel):
    tenant_id: str
    agent_id: str | None = None
    resource: str


@router.post("/configs")
async def create_config(body: RateLimitConfig):
    config_id = f"rl-{uuid.uuid4().hex[:10]}"
    result = await db.query(
        """
        CREATE rate_limit_config SET
            config_id   = $config_id,
            tenant_id   = $tenant_id,
            agent_id    = $agent_id,
            scope       = $scope,
            resource    = $resource,
            limit       = $limit,
            window      = $window,
            burst_limit = $burst_limit,
            active      = $active
        """,
        {
            "config_id": config_id,
            "tenant_id": body.tenant_id,
            "agent_id": body.agent_id,
            "scope": body.scope,
            "resource": body.resource,
            "limit": body.limit,
            "window": body.window,
            "burst_limit": body.burst_limit,
            "active": body.active,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to create rate limit config")
    return _s(rows[0])


@router.get("/configs")
async def list_configs(tenant_id: str | None = None, resource: str | None = None):
    filters, params = [], {}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if resource:
        filters.append("resource = $resource")
        params["resource"] = resource
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(
        f"SELECT * FROM rate_limit_config {where} ORDER BY resource ASC",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.delete("/configs/{config_id}")
async def delete_config(config_id: str):
    await db.query("DELETE rate_limit_config WHERE config_id = $config_id", {"config_id": config_id})
    return {"deleted": config_id}


@router.get("/usage")
async def get_quota_usage(tenant_id: str, resource: str | None = None, agent_id: str | None = None):
    filters = ["tenant_id = $tenant_id"]
    params: dict = {"tenant_id": tenant_id}
    if resource:
        filters.append("resource = $resource")
        params["resource"] = resource
    if agent_id:
        filters.append("agent_id = $agent_id")
        params["agent_id"] = agent_id
    where = f"WHERE {' AND '.join(filters)}"
    result = await db.query(
        f"SELECT * FROM quota_usage {where} ORDER BY window_start DESC LIMIT 100",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.post("/check")
async def check_rate_limit(body: QuotaCheck):
    """Check if a tenant/agent is currently rate-limited for a resource."""
    result = await db.query(
        """
        LET $config = SELECT * FROM rate_limit_config
            WHERE tenant_id = $tenant_id
              AND resource = $resource
              AND active = true
              AND (agent_id = $agent_id OR agent_id IS NONE)
            ORDER BY scope DESC
            LIMIT 1;

        LET $usage = SELECT * FROM quota_usage
            WHERE tenant_id = $tenant_id
              AND resource = $resource
              AND window_start >= time::now() - 1m
            LIMIT 1;

        RETURN {
            limited: array::len($usage) > 0
                AND array::len($config) > 0
                AND ($usage[0].request_count ?? 0) >= $config[0].limit,
            current_count: $usage[0].request_count ?? 0,
            limit: $config[0].limit ?? NONE,
            window: $config[0].window ?? '1m'
        };
        """,
        {
            "tenant_id": body.tenant_id,
            "resource": body.resource,
            "agent_id": body.agent_id,
        },
    )
    data = result[0].get("result") if result else {}
    return _s(data) if data else {"limited": False, "current_count": 0}


@router.post("/violations")
async def log_violation(tenant_id: str, resource: str, agent_id: str | None = None):
    """Record a rate limit violation."""
    result = await db.query(
        """
        CREATE rate_limit_violation SET
            tenant_id   = $tenant_id,
            agent_id    = $agent_id,
            resource    = $resource,
            occurred_at = time::now()
        """,
        {"tenant_id": tenant_id, "agent_id": agent_id, "resource": resource},
    )
    rows = result[0].get("result", []) if result else []
    return _s(rows[0]) if rows else {}
