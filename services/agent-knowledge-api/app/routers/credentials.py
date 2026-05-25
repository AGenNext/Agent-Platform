from typing import Any
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/credentials", tags=["credentials"])


def _s(v: Any) -> Any:
    if hasattr(v, "__str__") and ":" in str(v) and not isinstance(v, (str, int, float, bool)):
        return str(v)
    if isinstance(v, dict):
        return {k: _s(val) for k, val in v.items()}
    if isinstance(v, list):
        return [_s(i) for i in v]
    return v


class CredentialCreate(BaseModel):
    tenant_id: str
    agent_id: str | None = None
    name: str
    provider: str
    credential_type: str = "api_key"
    secret: str
    description: str | None = None
    scopes: list[str] = []
    metadata: dict = {}
    expires_at: str | None = None


class CredentialUpdate(BaseModel):
    secret: str | None = None
    description: str | None = None
    active: bool | None = None
    expires_at: str | None = None


@router.post("/")
async def store_credential(body: CredentialCreate):
    """Store a credential. Secret is write-only — never returned in GET responses."""
    cred_id = f"cred-{uuid.uuid4().hex[:12]}"
    result = await db.query(
        """
        CREATE credential SET
            cred_id         = $cred_id,
            tenant_id       = $tenant_id,
            agent_id        = $agent_id,
            name            = $name,
            provider        = $provider,
            credential_type = $credential_type,
            secret          = $secret,
            description     = $description,
            scopes          = $scopes,
            metadata        = $metadata,
            expires_at      = $expires_at,
            active          = true,
            last_used_at    = NONE
        """,
        {
            "cred_id": cred_id,
            "tenant_id": body.tenant_id,
            "agent_id": body.agent_id,
            "name": body.name,
            "provider": body.provider,
            "credential_type": body.credential_type,
            "secret": body.secret,
            "description": body.description,
            "scopes": body.scopes,
            "metadata": body.metadata,
            "expires_at": body.expires_at,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to store credential")
    # Strip secret from response
    rec = _s(rows[0])
    rec.pop("secret", None)
    rec["secret"] = "••••••••"
    return rec


@router.get("/")
async def list_credentials(
    tenant_id: str | None = None,
    agent_id: str | None = None,
    provider: str | None = None,
):
    """List credentials — secret field is always masked."""
    filters, params = [], {}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if agent_id:
        filters.append("agent_id = $agent_id")
        params["agent_id"] = agent_id
    if provider:
        filters.append("provider = $provider")
        params["provider"] = provider
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(
        f"""
        SELECT cred_id, tenant_id, agent_id, name, provider,
               credential_type, description, scopes, active,
               last_used_at, expires_at, created_at
        FROM credential {where}
        ORDER BY provider ASC, name ASC
        """,
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/{cred_id}")
async def get_credential(cred_id: str):
    """Get credential metadata — secret never returned."""
    result = await db.query(
        """
        SELECT cred_id, tenant_id, agent_id, name, provider,
               credential_type, description, scopes, active,
               last_used_at, expires_at, created_at
        FROM credential WHERE cred_id = $cred_id LIMIT 1
        """,
        {"cred_id": cred_id},
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(404, "Credential not found")
    return _s(rows[0])


@router.patch("/{cred_id}")
async def update_credential(cred_id: str, body: CredentialUpdate):
    """Rotate secret or toggle active state."""
    updates, params = [], {"cred_id": cred_id}
    if body.secret is not None:
        updates.append("secret = $secret")
        params["secret"] = body.secret
    if body.active is not None:
        updates.append("active = $active")
        params["active"] = body.active
    if body.description is not None:
        updates.append("description = $description")
        params["description"] = body.description
    if body.expires_at is not None:
        updates.append("expires_at = $expires_at")
        params["expires_at"] = body.expires_at
    if not updates:
        raise HTTPException(400, "Nothing to update")
    await db.query(
        f"UPDATE credential SET {', '.join(updates)} WHERE cred_id = $cred_id",
        params,
    )
    return {"cred_id": cred_id, "updated": True}


@router.delete("/{cred_id}")
async def delete_credential(cred_id: str):
    await db.query("DELETE credential WHERE cred_id = $cred_id", {"cred_id": cred_id})
    return {"deleted": cred_id}


@router.post("/{cred_id}/use")
async def mark_used(cred_id: str):
    """Touch last_used_at when a credential is consumed by an agent."""
    await db.query(
        "UPDATE credential SET last_used_at = time::now() WHERE cred_id = $cred_id",
        {"cred_id": cred_id},
    )
    return {"cred_id": cred_id, "last_used_at": "now"}
