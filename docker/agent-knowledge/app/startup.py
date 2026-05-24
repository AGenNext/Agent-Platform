"""Apply schema.surql and seed default routing rules on first boot."""

import os
from pathlib import Path

from .db import get_db

_SCHEMA_PATH = Path(__file__).parent / "schema.surql"

_DEFAULT_ROUTING_RULES = [
    {
        "task_type": "research",
        "preferred_provider": "ollama",
        "models": [
            {"model_id": "llama3", "provider": "ollama", "priority": 1, "max_cost_per_call": 0.0},
            {"model_id": "claude-sonnet-4-6", "provider": "anthropic", "priority": 2, "max_cost_per_call": 0.05},
        ],
        "max_cost_per_call": 0.05,
        "daily_budget": 5.0,
        "enabled": True,
    },
    {
        "task_type": "generation",
        "preferred_provider": "anthropic",
        "models": [
            {"model_id": "claude-sonnet-4-6", "provider": "anthropic", "priority": 1, "max_cost_per_call": 0.10},
            {"model_id": "llama3", "provider": "ollama", "priority": 2, "max_cost_per_call": 0.0},
        ],
        "max_cost_per_call": 0.10,
        "daily_budget": 20.0,
        "enabled": True,
    },
    {
        "task_type": "eval",
        "preferred_provider": "ollama",
        "models": [
            {"model_id": "llama3", "provider": "ollama", "priority": 1, "max_cost_per_call": 0.0},
        ],
        "max_cost_per_call": 0.02,
        "daily_budget": 2.0,
        "enabled": True,
    },
]


async def apply_schema() -> None:
    schema_sql = _SCHEMA_PATH.read_text()
    async with get_db() as db:
        await db.query(schema_sql)


async def seed_routing_rules() -> None:
    async with get_db() as db:
        for rule in _DEFAULT_ROUTING_RULES:
            existing = await db.query(
                "SELECT id FROM routing_rules WHERE task_type = $tt LIMIT 1",
                {"tt": rule["task_type"]},
            )
            rows = existing[0].get("result", []) if existing else []
            if not rows:
                await db.create("routing_rules", rule)


async def run_startup() -> None:
    await apply_schema()
    await seed_routing_rules()
    # Discover available models — non-fatal if providers are unreachable
    try:
        from .discovery import run_discovery
        await run_discovery()
    except Exception:
        pass
