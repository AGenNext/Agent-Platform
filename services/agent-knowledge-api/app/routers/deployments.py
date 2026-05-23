from typing import Any
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/deployments", tags=["deployments"])


def _s(v: Any) -> Any:
    if hasattr(v, "__str__") and ":" in str(v) and not isinstance(v, (str, int, float, bool)):
        return str(v)
    if isinstance(v, dict):
        return {k: _s(val) for k, val in v.items()}
    if isinstance(v, list):
        return [_s(i) for i in v]
    return v


class DeploymentCreate(BaseModel):
    agent_id: str
    tenant_id: str
    version: str
    strategy: str = "rolling"
    traffic_pct: float = 100.0
    previous_version: str | None = None
    auto_rollback: bool = True
    rollback_threshold: float = 0.05
    health_checks_required: int = 3
    deployed_by: str | None = None
    notes: str | None = None


class VersionCreate(BaseModel):
    agent_id: str
    tenant_id: str
    version: str
    version_num: int
    change_type: str = "config"
    changelog: str | None = None
    snapshot: dict = {}
    approved_by: str | None = None


@router.post("/")
async def create_deployment(body: DeploymentCreate):
    deployment_id = f"deploy-{uuid.uuid4().hex[:12]}"
    result = await db.query(
        """
        CREATE deployment SET
            deployment_id       = $deployment_id,
            agent_id            = $agent_id,
            tenant_id           = $tenant_id,
            version             = $version,
            strategy            = $strategy,
            traffic_pct         = $traffic_pct,
            previous_version    = $previous_version,
            status              = 'pending',
            auto_rollback       = $auto_rollback,
            rollback_threshold  = $rollback_threshold,
            health_checks_required = $health_checks_required,
            deployed_by         = $deployed_by,
            notes               = $notes,
            started_at          = time::now()
        """,
        {
            "deployment_id": deployment_id,
            "agent_id": body.agent_id,
            "tenant_id": body.tenant_id,
            "version": body.version,
            "strategy": body.strategy,
            "traffic_pct": body.traffic_pct,
            "previous_version": body.previous_version,
            "auto_rollback": body.auto_rollback,
            "rollback_threshold": body.rollback_threshold,
            "health_checks_required": body.health_checks_required,
            "deployed_by": body.deployed_by,
            "notes": body.notes,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to create deployment")
    return _s(rows[0])


@router.get("/")
async def list_deployments(
    tenant_id: str | None = None,
    agent_id: str | None = None,
    status: str | None = None,
    limit: int = 50,
):
    filters, params = [], {"limit": limit}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if agent_id:
        filters.append("agent_id = $agent_id")
        params["agent_id"] = agent_id
    if status:
        filters.append("status = $status")
        params["status"] = status
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(
        f"SELECT * FROM deployment {where} ORDER BY started_at DESC LIMIT $limit",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.get("/{deployment_id}")
async def get_deployment(deployment_id: str):
    result = await db.query(
        "SELECT * FROM deployment WHERE deployment_id = $deployment_id LIMIT 1",
        {"deployment_id": deployment_id},
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(404, "Deployment not found")
    return _s(rows[0])


@router.patch("/{deployment_id}/status")
async def update_deployment_status(deployment_id: str, status: str, health_check: bool = False):
    valid = {"pending", "in_progress", "healthy", "degraded", "rolled_back", "failed"}
    if status not in valid:
        raise HTTPException(400, f"status must be one of {valid}")

    updates = ["status = $status"]
    params: dict = {"deployment_id": deployment_id, "status": status}

    if status in ("healthy", "rolled_back", "failed"):
        updates.append("completed_at = time::now()")
    if health_check:
        updates.append("health_checks_passed += 1")

    await db.query(
        f"UPDATE deployment SET {', '.join(updates)} WHERE deployment_id = $deployment_id",
        params,
    )
    return {"deployment_id": deployment_id, "status": status}


# ─── Agent version history ────────────────────────────────────────────────────

@router.get("/agents/{agent_id}/versions")
async def list_versions(agent_id: str):
    result = await db.query(
        """
        SELECT version, version_num, change_type, changelog, created_at, created_by, approved_by
        FROM agent_version
        WHERE agent_id = $agent_id
        ORDER BY version_num DESC
        """,
        {"agent_id": agent_id},
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.post("/agents/{agent_id}/versions")
async def create_version(agent_id: str, body: VersionCreate):
    result = await db.query(
        """
        CREATE agent_version SET
            agent_id    = $agent_id,
            tenant_id   = $tenant_id,
            version     = $version,
            version_num = $version_num,
            change_type = $change_type,
            changelog   = $changelog,
            snapshot    = $snapshot,
            approved_by = $approved_by,
            created_at  = time::now()
        """,
        {
            "agent_id": agent_id,
            "tenant_id": body.tenant_id,
            "version": body.version,
            "version_num": body.version_num,
            "change_type": body.change_type,
            "changelog": body.changelog,
            "snapshot": body.snapshot,
            "approved_by": body.approved_by,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to create version")
    return _s(rows[0])
