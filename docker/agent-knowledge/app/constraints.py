"""
Agent-Constraints — policy enforcement for model routing.

Policy types and enforcement:
  workspace_budget  — daily/monthly spend cap per workspace (hard block)
  objective_budget  — max total cost allowed for a single objective (hard block)
  model_allowlist   — only these model_ids are permitted for this scope (hard block)
  model_denylist    — these model_ids are forbidden for this scope (hard block)
  max_cost_per_call — override max cost per call for this scope
  token_quota       — max tokens (input+output) per day for this scope

Scopes:
  global            — applies to all traffic
  workspace:<id>    — applies to a specific workspace
  task_type:<name>  — applies to a specific task type
  objective:<id>    — applies to a specific objective
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from .db import get_db
from .events import emit


class PolicyViolation(Exception):
    def __init__(self, policy_type: str, scope: str, message: str) -> None:
        self.policy_type = policy_type
        self.scope = scope
        self.message = message
        super().__init__(f"[{policy_type}@{scope}] {message}")


async def enforce(
    model_id: str,
    provider: str,
    estimated_cost: float,
    task_type: str,
    objective_id: Optional[str] = None,
    workspace_id: Optional[str] = None,
) -> None:
    """
    Check all applicable policies. Raises PolicyViolation if any hard gate fails.
    Call before executing a model request.
    """
    scopes = _applicable_scopes(task_type, objective_id, workspace_id)
    policies = await _load_policies(scopes)

    for policy in policies:
        if not policy.get("enabled", True):
            continue
        ptype = policy["policy_type"]
        scope = policy["scope"]

        if ptype == "model_allowlist":
            allowed = policy.get("value", [])
            if allowed and model_id not in allowed:
                raise PolicyViolation(ptype, scope, f"{model_id} not in allowlist {allowed}")

        elif ptype == "model_denylist":
            denied = policy.get("value", [])
            if model_id in denied:
                raise PolicyViolation(ptype, scope, f"{model_id} is denied by policy")

        elif ptype == "max_cost_per_call":
            cap = float(policy.get("value", 999))
            if estimated_cost > cap:
                raise PolicyViolation(ptype, scope, f"estimated ${estimated_cost:.4f} > cap ${cap:.4f}")

        elif ptype == "workspace_budget" and workspace_id:
            period = policy.get("period", "daily")
            cap = float(policy.get("value", 999))
            spent = await _workspace_spend(workspace_id, period)
            if spent + estimated_cost > cap:
                raise PolicyViolation(
                    ptype, scope,
                    f"workspace {workspace_id} would exceed {period} budget: ${spent:.4f}+${estimated_cost:.4f} > ${cap:.4f}"
                )

        elif ptype == "objective_budget" and objective_id:
            cap = float(policy.get("value", 999))
            spent = await _objective_spend(objective_id)
            if spent + estimated_cost > cap:
                raise PolicyViolation(
                    ptype, scope,
                    f"objective {objective_id} would exceed budget: ${spent:.4f}+${estimated_cost:.4f} > ${cap:.4f}"
                )

        elif ptype == "token_quota":
            cap = int(policy.get("value", 99_999_999))
            used = await _daily_tokens(workspace_id or "global")
            if used >= cap:
                raise PolicyViolation(ptype, scope, f"daily token quota {cap} exhausted ({used} used)")


async def create_policy(
    policy_type: str,
    value: Any,
    scope: str = "global",
    target_id: Optional[str] = None,
    unit: str = "usd",
    period: str = "daily",
) -> Dict[str, Any]:
    async with get_db() as db:
        result = await db.create("agent_constraints", {
            "policy_type": policy_type,
            "scope": scope,
            "target_id": target_id,
            "value": value,
            "unit": unit,
            "period": period,
            "enabled": True,
            "created_at": _now(),
            "updated_at": _now(),
        })
    record = _norm(result[0] if isinstance(result, list) else result)
    await emit("platform", "constraints", "policy_created", {"policy_type": policy_type, "scope": scope})
    return record


async def list_policies(scope: Optional[str] = None) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if scope:
            results = await db.query(
                "SELECT * FROM agent_constraints WHERE scope = $s ORDER BY policy_type",
                {"s": scope},
            )
        else:
            results = await db.query("SELECT * FROM agent_constraints ORDER BY scope, policy_type")
    return [_norm(r) for r in _rows(results)]


async def delete_policy(policy_id: str) -> None:
    async with get_db() as db:
        await db.delete(f"agent_constraints:{policy_id}")


# ── Internal ──────────────────────────────────────────────────────────────────

def _applicable_scopes(
    task_type: str,
    objective_id: Optional[str],
    workspace_id: Optional[str],
) -> List[str]:
    scopes = ["global", f"task_type:{task_type}"]
    if workspace_id:
        scopes.append(f"workspace:{workspace_id}")
    if objective_id:
        scopes.append(f"objective:{objective_id}")
    return scopes


async def _load_policies(scopes: List[str]) -> List[Dict[str, Any]]:
    async with get_db() as db:
        results = await db.query(
            "SELECT * FROM agent_constraints WHERE scope INSIDE $scopes AND enabled = true",
            {"scopes": scopes},
        )
    return [_norm(r) for r in _rows(results)]


async def _workspace_spend(workspace_id: str, period: str) -> float:
    interval = {"daily": "1d", "weekly": "7d", "monthly": "30d"}.get(period, "1d")
    async with get_db() as db:
        results = await db.query(
            f"SELECT math::sum(cost_usd) AS spent FROM usage_records "
            f"WHERE workspace_id = $wid AND recorded_at > time::now() - {interval} GROUP ALL",
            {"wid": workspace_id},
        )
    rows = _rows(results)
    return float(rows[0].get("spent") or 0.0) if rows else 0.0


async def _objective_spend(objective_id: str) -> float:
    async with get_db() as db:
        results = await db.query(
            "SELECT math::sum(cost_usd) AS spent FROM usage_records WHERE objective_id = $oid GROUP ALL",
            {"oid": objective_id},
        )
    rows = _rows(results)
    return float(rows[0].get("spent") or 0.0) if rows else 0.0


async def _daily_tokens(scope_key: str) -> int:
    async with get_db() as db:
        results = await db.query(
            "SELECT math::sum(input_tokens + output_tokens) AS tokens FROM usage_records "
            "WHERE recorded_at > time::now() - 1d GROUP ALL",
        )
    rows = _rows(results)
    return int(rows[0].get("tokens") or 0) if rows else 0


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
