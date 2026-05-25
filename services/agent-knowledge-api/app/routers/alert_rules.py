from typing import Any
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.db.surrealdb import db

router = APIRouter(prefix="/alerts", tags=["alerts"])


def _s(v: Any) -> Any:
    if hasattr(v, "__str__") and ":" in str(v) and not isinstance(v, (str, int, float, bool)):
        return str(v)
    if isinstance(v, dict):
        return {k: _s(val) for k, val in v.items()}
    if isinstance(v, list):
        return [_s(i) for i in v]
    return v


class AlertRuleCreate(BaseModel):
    tenant_id: str
    name: str
    description: str | None = None
    metric_name: str
    condition: str = "gt"
    threshold: float
    window: str = "5m"
    severity: str = "warning"
    notification_channels: list[str] = []
    cooldown: str = "15m"
    active: bool = True


class AlertRuleUpdate(BaseModel):
    threshold: float | None = None
    active: bool | None = None
    severity: str | None = None
    cooldown: str | None = None


@router.post("/rules")
async def create_rule(body: AlertRuleCreate):
    rule_id = f"rule-{uuid.uuid4().hex[:10]}"
    result = await db.query(
        """
        CREATE alert_rule SET
            rule_id                = $rule_id,
            tenant_id              = $tenant_id,
            name                   = $name,
            description            = $description,
            metric_name            = $metric_name,
            condition              = $condition,
            threshold              = $threshold,
            window                 = $window,
            severity               = $severity,
            notification_channels  = $notification_channels,
            cooldown               = $cooldown,
            active                 = $active,
            fire_count             = 0
        """,
        {
            "rule_id": rule_id,
            "tenant_id": body.tenant_id,
            "name": body.name,
            "description": body.description,
            "metric_name": body.metric_name,
            "condition": body.condition,
            "threshold": body.threshold,
            "window": body.window,
            "severity": body.severity,
            "notification_channels": body.notification_channels,
            "cooldown": body.cooldown,
            "active": body.active,
        },
    )
    rows = result[0].get("result", []) if result else []
    if not rows:
        raise HTTPException(500, "Failed to create alert rule")
    return _s(rows[0])


@router.get("/rules")
async def list_rules(tenant_id: str | None = None, active: bool | None = None):
    filters, params = [], {}
    if tenant_id:
        filters.append("tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if active is not None:
        filters.append("active = $active")
        params["active"] = active
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(
        f"SELECT * FROM alert_rule {where} ORDER BY severity ASC, name ASC",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.patch("/rules/{rule_id}")
async def update_rule(rule_id: str, body: AlertRuleUpdate):
    updates, params = [], {"rule_id": rule_id}
    if body.threshold is not None:
        updates.append("threshold = $threshold")
        params["threshold"] = body.threshold
    if body.active is not None:
        updates.append("active = $active")
        params["active"] = body.active
    if body.severity is not None:
        updates.append("severity = $severity")
        params["severity"] = body.severity
    if body.cooldown is not None:
        updates.append("cooldown = $cooldown")
        params["cooldown"] = body.cooldown
    if not updates:
        raise HTTPException(400, "Nothing to update")
    await db.query(
        f"UPDATE alert_rule SET {', '.join(updates)} WHERE rule_id = $rule_id",
        params,
    )
    return {"rule_id": rule_id, "updated": True}


@router.delete("/rules/{rule_id}")
async def delete_rule(rule_id: str):
    await db.query("DELETE alert_rule WHERE rule_id = $rule_id", {"rule_id": rule_id})
    return {"deleted": rule_id}


@router.get("/instances")
async def list_instances(
    tenant_id: str | None = None,
    status: str | None = None,
    severity: str | None = None,
    limit: int = 100,
):
    filters, params = [], {"limit": limit}
    if tenant_id:
        filters.append("rule_id.tenant_id = $tenant_id")
        params["tenant_id"] = tenant_id
    if status:
        filters.append("status = $status")
        params["status"] = status
    if severity:
        filters.append("severity = $severity")
        params["severity"] = severity
    where = f"WHERE {' AND '.join(filters)}" if filters else ""
    result = await db.query(
        f"SELECT * FROM alert_instance {where} ORDER BY fired_at DESC LIMIT $limit",
        params,
    )
    rows = result[0].get("result", []) if result else []
    return [_s(r) for r in rows]


@router.post("/instances/{instance_id}/resolve")
async def resolve_instance(instance_id: str, resolved_by: str | None = None):
    await db.query(
        """
        UPDATE alert_instance SET
            status      = 'resolved',
            resolved_at = time::now(),
            resolved_by = $resolved_by
        WHERE id = $instance_id
        """,
        {"instance_id": instance_id, "resolved_by": resolved_by},
    )
    return {"instance_id": instance_id, "status": "resolved"}


@router.post("/evaluate")
async def evaluate_rules(tenant_id: str):
    """
    Manually trigger rule evaluation for a tenant.
    In production this runs on a schedule via DEFINE EVENT or a cron worker.
    """
    # Fetch active rules for tenant
    rules_result = await db.query(
        "SELECT * FROM alert_rule WHERE tenant_id = $tenant_id AND active = true",
        {"tenant_id": tenant_id},
    )
    rules = rules_result[0].get("result", []) if rules_result else []
    fired = []

    for rule in rules:
        metric_name = rule.get("metric_name")
        threshold = rule.get("threshold", 0)
        condition = rule.get("condition", "gt")
        window = rule.get("window", "5m")

        # Compute current metric value in window
        val_result = await db.query(
            """
            SELECT math::mean(value) AS current_value
            FROM metric
            WHERE name = $name
              AND tenant_id = $tenant_id
              AND recorded_at >= time::now() - $window
            """,
            {"name": metric_name, "tenant_id": tenant_id, "window": window},
        )
        val_rows = val_result[0].get("result", []) if val_result else []
        current = (val_rows[0].get("current_value") or 0.0) if val_rows else 0.0

        # Check condition
        triggered = (
            (condition == "gt" and current > threshold) or
            (condition == "gte" and current >= threshold) or
            (condition == "lt" and current < threshold) or
            (condition == "lte" and current <= threshold) or
            (condition == "eq" and current == threshold)
        )

        if triggered:
            inst_result = await db.query(
                """
                CREATE alert_instance SET
                    rule_id       = $rule_ref,
                    severity      = $severity,
                    metric_value  = $current,
                    threshold     = $threshold,
                    status        = 'firing',
                    fired_at      = time::now(),
                    message       = string::concat($name, ' is ', string($current), ' (threshold: ', string($threshold), ')')
                """,
                {
                    "rule_ref": rule.get("id"),
                    "severity": rule.get("severity", "warning"),
                    "current": current,
                    "threshold": threshold,
                    "name": metric_name,
                },
            )
            inst_rows = inst_result[0].get("result", []) if inst_result else []
            if inst_rows:
                fired.append(_s(inst_rows[0]))

    return {"rules_evaluated": len(rules), "alerts_fired": len(fired), "instances": fired}
