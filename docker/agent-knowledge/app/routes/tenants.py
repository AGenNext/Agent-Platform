from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..tenants import (
    create_tenant, get_tenant, list_tenants, update_tenant,
    create_user, list_users, update_user_role,
    create_api_key, list_api_keys, revoke_api_key,
    get_subscription, change_plan,
    write_audit, list_audit_logs,
    PLAN_LIMITS, ROLES,
)

router = APIRouter(prefix="/tenants", tags=["tenants"])


# ── Tenant endpoints ──────────────────────────────────────────────────────────

class TenantCreate(BaseModel):
    name: str
    plan: str = "free"


class TenantUpdate(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None


@router.get("")
async def api_list_tenants():
    return await list_tenants()


@router.post("", status_code=201)
async def api_create_tenant(body: TenantCreate):
    return await create_tenant(body.name, body.plan)


@router.get("/{tenant_id}")
async def api_get_tenant(tenant_id: str):
    t = await get_tenant(tenant_id)
    if not t:
        raise HTTPException(404, "Tenant not found")
    return t


@router.patch("/{tenant_id}")
async def api_update_tenant(tenant_id: str, body: TenantUpdate):
    fields = {k: v for k, v in body.model_dump().items() if v is not None}
    return await update_tenant(tenant_id, fields)


# ── User endpoints ────────────────────────────────────────────────────────────

class UserInvite(BaseModel):
    email: str
    display_name: str = ""
    role: str = "viewer"
    password: Optional[str] = None


class RoleUpdate(BaseModel):
    role: str


@router.get("/{tenant_id}/users")
async def api_list_users(tenant_id: str):
    return await list_users(tenant_id)


@router.post("/{tenant_id}/users", status_code=201)
async def api_invite_user(tenant_id: str, body: UserInvite):
    if body.role not in ROLES:
        raise HTTPException(400, f"Invalid role. Choose: {ROLES}")
    return await create_user(
        tenant_id, body.email, body.display_name, body.role, body.password
    )


@router.patch("/{tenant_id}/users/{user_id}/role")
async def api_update_role(tenant_id: str, user_id: str, body: RoleUpdate):
    user = await update_user_role(user_id, body.role)
    if not user:
        raise HTTPException(400, f"Invalid role. Choose: {ROLES}")
    return user


# ── API Key endpoints ─────────────────────────────────────────────────────────

class ApiKeyCreate(BaseModel):
    name: str
    scopes: List[str] = ["read", "write"]
    user_id: Optional[str] = None


@router.get("/{tenant_id}/api-keys")
async def api_list_keys(tenant_id: str):
    return await list_api_keys(tenant_id)


@router.post("/{tenant_id}/api-keys", status_code=201)
async def api_create_key(tenant_id: str, body: ApiKeyCreate):
    return await create_api_key(tenant_id, body.name, body.scopes, body.user_id)


@router.delete("/{tenant_id}/api-keys/{key_id}", status_code=204)
async def api_revoke_key(tenant_id: str, key_id: str):
    await revoke_api_key(key_id)


# ── Billing endpoints ─────────────────────────────────────────────────────────

class PlanChange(BaseModel):
    plan: str


@router.get("/{tenant_id}/billing")
async def api_billing(tenant_id: str):
    sub = await get_subscription(tenant_id)
    if not sub:
        raise HTTPException(404, "No subscription found")
    return sub


@router.post("/{tenant_id}/billing/plan")
async def api_change_plan(tenant_id: str, body: PlanChange):
    sub = await change_plan(tenant_id, body.plan)
    if not sub:
        raise HTTPException(400, f"Invalid plan. Choose: {list(PLAN_LIMITS)}")
    return sub


@router.get("/plans")
async def api_list_plans():
    return [
        {"plan_id": pid, "limits": limits}
        for pid, limits in PLAN_LIMITS.items()
    ]


# ── Audit log endpoints ───────────────────────────────────────────────────────

class AuditWrite(BaseModel):
    action: str
    actor_id: Optional[str] = None
    actor_type: str = "system"
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    result: str = "success"
    metadata: Dict[str, Any] = {}


@router.get("/{tenant_id}/audit-logs")
async def api_audit_logs(tenant_id: str, action: Optional[str] = None, limit: int = 100):
    return await list_audit_logs(tenant_id, action_filter=action, limit=min(limit, 500))


@router.post("/{tenant_id}/audit-logs", status_code=201)
async def api_write_audit(tenant_id: str, body: AuditWrite):
    return await write_audit(
        tenant_id, body.action, body.actor_id, body.actor_type,
        body.resource_type, body.resource_id, body.result, body.metadata,
    )
