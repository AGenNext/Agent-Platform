"""
Tenants, Users, RBAC, API Keys — multi-tenant SaaS layer.

API keys: raw key shown once at creation, only sha256 hash stored.
Key format: rg_<32 random hex chars>
Prefix (first 10 chars) stored for display.

Roles (least → most privileged): viewer → editor → admin → owner
"""

import hashlib
import os
import secrets
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit

# Default subscription plan limits
PLAN_LIMITS: Dict[str, Dict[str, Any]] = {
    "free":       {"monthly_budget_usd": 10.0,  "api_calls_per_day": 100,  "kb_count": 3,  "users": 3},
    "pro":        {"monthly_budget_usd": 200.0, "api_calls_per_day": 5000, "kb_count": 20, "users": 20},
    "enterprise": {"monthly_budget_usd": 0.0,   "api_calls_per_day": 0,   "kb_count": 0,  "users": 0},
}

ROLES = ["viewer", "editor", "admin", "owner"]


# ── Tenants ───────────────────────────────────────────────────────────────────

async def create_tenant(name: str, plan: str = "free") -> Dict[str, Any]:
    slug = _slugify(name)
    async with get_db() as db:
        # Ensure slug is unique
        existing = await db.query(
            "SELECT id FROM tenants WHERE slug = $s LIMIT 1", {"s": slug}
        )
        if _rows(existing):
            slug = f"{slug}-{secrets.token_hex(3)}"
        record = {
            "name": name,
            "slug": slug,
            "plan": plan if plan in PLAN_LIMITS else "free",
            "status": "active",
            "settings": {},
            "created_at": _now(),
            "updated_at": _now(),
        }
        result = await db.create("tenants", record)
    tenant = _norm(result[0] if isinstance(result, list) else result)

    # Seed default plan subscription
    await _create_subscription(tenant["id"], plan)

    await emit("tenant", tenant["id"], "created", {"name": name, "plan": plan})
    return tenant


async def get_tenant(tenant_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM tenants WHERE id = $id OR slug = $id LIMIT 1",
            {"id": tenant_id},
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def list_tenants() -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query("SELECT * FROM tenants ORDER BY created_at DESC")
    return [_norm(r) for r in _rows(results)]


async def update_tenant(tenant_id: str, fields: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    fields["updated_at"] = _now()
    async with get_db() as db:
        await db.merge(tenant_id, fields)
        results = await db.query(
            "SELECT * FROM tenants WHERE id = $id LIMIT 1", {"id": tenant_id}
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


# ── Users ─────────────────────────────────────────────────────────────────────

async def create_user(
    tenant_id: str,
    email: str,
    display_name: str = "",
    role: str = "viewer",
    password: Optional[str] = None,
) -> Dict[str, Any]:
    if role not in ROLES:
        role = "viewer"
    async with get_db() as db:
        record = {
            "tenant_id": tenant_id,
            "email": email.lower().strip(),
            "display_name": display_name or email.split("@")[0],
            "role": role,
            "status": "active",
            "password_hash": _hash_password(password) if password else None,
            "created_at": _now(),
            "updated_at": _now(),
        }
        result = await db.create("users", record)
    user = _norm(result[0] if isinstance(result, list) else result)
    await emit("tenant", tenant_id, "user.created", {"email": email, "role": role})
    return user


async def get_user(user_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM users WHERE id = $id LIMIT 1", {"id": user_id}
        )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


async def list_users(tenant_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM users WHERE tenant_id = $t ORDER BY created_at ASC",
            {"t": tenant_id},
        )
    users = [_norm(r) for r in _rows(results)]
    # Never return password hashes
    for u in users:
        u.pop("password_hash", None)
    return users


async def update_user_role(user_id: str, role: str) -> Optional[Dict[str, Any]]:
    if role not in ROLES:
        return None
    async with get_db() as db:
        await db.merge(user_id, {"role": role, "updated_at": _now()})
        results = await db.query(
            "SELECT * FROM users WHERE id = $id LIMIT 1", {"id": user_id}
        )
    rows = _rows(results)
    u = _norm(rows[0]) if rows else None
    if u:
        u.pop("password_hash", None)
    return u


# ── API Keys ──────────────────────────────────────────────────────────────────

async def create_api_key(
    tenant_id: str,
    name: str,
    scopes: Optional[List[str]] = None,
    user_id: Optional[str] = None,
) -> Dict[str, Any]:
    raw_key = f"rg_{secrets.token_hex(24)}"  # rg_ + 48 hex chars
    prefix = raw_key[:10]
    key_hash = hashlib.sha256(raw_key.encode()).hexdigest()

    async with get_db() as db:
        record = {
            "tenant_id": tenant_id,
            "user_id": user_id,
            "name": name,
            "key_prefix": prefix,
            "key_hash": key_hash,
            "scopes": scopes or ["read", "write"],
            "status": "active",
            "created_at": _now(),
        }
        result = await db.create("api_keys", record)
    key_record = _norm(result[0] if isinstance(result, list) else result)
    await emit("tenant", tenant_id, "api_key.created", {"name": name, "prefix": prefix})

    # Return raw key in response — only time it's visible
    key_record["raw_key"] = raw_key
    return key_record


async def list_api_keys(tenant_id: str) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM api_keys WHERE tenant_id = $t ORDER BY created_at DESC",
            {"t": tenant_id},
        )
    keys = [_norm(r) for r in _rows(results)]
    for k in keys:
        k.pop("key_hash", None)  # never return hash in list
    return keys


async def revoke_api_key(key_id: str) -> bool:
    async with get_db() as db:
        await db.merge(key_id, {"status": "revoked"})
    return True


async def validate_api_key(raw_key: str) -> Optional[Dict[str, Any]]:
    """Returns the key record (with tenant_id) if valid + active."""
    key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM api_keys WHERE key_hash = $h AND status = 'active' LIMIT 1",
            {"h": key_hash},
        )
        rows = _rows(results)
        if not rows:
            return None
        key_record = _norm(rows[0])
        # Update last_used
        await db.merge(key_record["id"], {"last_used_at": _now()})
    key_record.pop("key_hash", None)
    return key_record


# ── Subscriptions ─────────────────────────────────────────────────────────────

async def get_subscription(tenant_id: str) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM billing_subscriptions WHERE tenant_id = $t "
            "ORDER BY created_at DESC LIMIT 1",
            {"t": tenant_id},
        )
    rows = _rows(results)
    if not rows:
        return None
    sub = _norm(rows[0])
    sub["limits"] = PLAN_LIMITS.get(sub.get("plan_id", "free"), PLAN_LIMITS["free"])
    return sub


async def _create_subscription(tenant_id: str, plan_id: str) -> None:
    async with get_db() as db:
        await db.create("billing_subscriptions", {
            "tenant_id": tenant_id,
            "plan_id": plan_id if plan_id in PLAN_LIMITS else "free",
            "status": "active",
            "current_period_start": _now(),
            "created_at": _now(),
            "updated_at": _now(),
        })


async def change_plan(tenant_id: str, new_plan: str) -> Optional[Dict[str, Any]]:
    if new_plan not in PLAN_LIMITS:
        return None
    async with get_db() as db:
        await db.query(
            "UPDATE billing_subscriptions SET plan_id = $p, updated_at = $t "
            "WHERE tenant_id = $tenant",
            {"p": new_plan, "t": _now(), "tenant": tenant_id},
        )
        await db.query(
            "UPDATE tenants SET plan = $p, updated_at = $t WHERE id = $id OR slug = $id",
            {"p": new_plan, "t": _now(), "id": tenant_id},
        )
    await emit("tenant", tenant_id, "plan.changed", {"plan": new_plan})
    return await get_subscription(tenant_id)


# ── Audit Logs ────────────────────────────────────────────────────────────────

async def write_audit(
    tenant_id: str,
    action: str,
    actor_id: Optional[str] = None,
    actor_type: str = "system",
    resource_type: Optional[str] = None,
    resource_id: Optional[str] = None,
    result: str = "success",
    metadata: Optional[Dict[str, Any]] = None,
    ip_address: Optional[str] = None,
) -> Dict[str, Any]:
    async with get_db() as db:
        record = {
            "tenant_id": tenant_id,
            "actor_id": actor_id,
            "actor_type": actor_type,
            "action": action,
            "resource_type": resource_type,
            "resource_id": resource_id,
            "result": result,
            "metadata": metadata or {},
            "ip_address": ip_address,
            "occurred_at": _now(),
        }
        res = await db.create("audit_logs", record)
    return _norm(res[0] if isinstance(res, list) else res)


async def list_audit_logs(
    tenant_id: str,
    action_filter: Optional[str] = None,
    limit: int = 100,
) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if action_filter:
            results = await db.query(
                "SELECT * FROM audit_logs WHERE tenant_id = $t AND action CONTAINS $a "
                "ORDER BY occurred_at DESC LIMIT $l",
                {"t": tenant_id, "a": action_filter, "l": limit},
            )
        else:
            results = await db.query(
                "SELECT * FROM audit_logs WHERE tenant_id = $t "
                "ORDER BY occurred_at DESC LIMIT $l",
                {"t": tenant_id, "l": limit},
            )
    return [_norm(r) for r in _rows(results)]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _slugify(name: str) -> str:
    import re
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:40]


def _hash_password(password: str) -> str:
    salt = os.getenv("SECRET_KEY", "realgraph-default-salt")
    return hashlib.sha256(f"{salt}:{password}".encode()).hexdigest()


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _rows(result: Any) -> List[Dict[str, Any]]:
    if not result:
        return []
    if isinstance(result, list) and result and isinstance(result[0], dict):
        return result[0].get("result", result)
    return result if isinstance(result, list) else []


def _norm(record: Dict[str, Any]) -> Dict[str, Any]:
    if "id" in record:
        record["id"] = str(record["id"])
    return record
