"""E2E: model routing rules and FinOps usage tracking."""
import uuid
import pytest

pytestmark = pytest.mark.asyncio

_TASK_TYPE = f"e2e-summarise-{uuid.uuid4().hex[:8]}"


async def test_upsert_and_get_routing_rule(api):
    r = await api.put("/model-router/rules", json={
        "task_type": _TASK_TYPE,
        "preferred_provider": "anthropic",
        "models": [
            {"model_id": "claude-haiku-4-5", "provider": "anthropic", "priority": 1, "max_cost_per_call": 0.002},
            {"model_id": "claude-sonnet-4-6", "provider": "anthropic", "priority": 2, "max_cost_per_call": 0.015},
        ],
        "max_cost_per_call": 0.015,
        "daily_budget": 5.0,
        "enabled": True,
    })
    assert r.status_code == 200, r.text
    rule = r.json()
    assert rule["task_type"] == _TASK_TYPE
    assert rule["enabled"] is True

    # Fetch by task_type
    r = await api.get(f"/model-router/rules/{_TASK_TYPE}")
    assert r.status_code == 200
    assert r.json()["task_type"] == _TASK_TYPE


async def test_list_routing_rules_contains_upserted(api):
    r = await api.get("/model-router/rules")
    assert r.status_code == 200
    types = [rule["task_type"] for rule in r.json()]
    assert _TASK_TYPE in types


async def test_model_selection_returns_candidate(api):
    r = await api.post("/model-router/select", json={"task_type": _TASK_TYPE})
    assert r.status_code == 200, r.text
    sel = r.json()
    assert "model_id" in sel
    assert "provider" in sel
    assert "rationale" in sel


async def test_model_selection_fallback_for_unknown_type(api):
    r = await api.post("/model-router/select", json={"task_type": "unknown-task-type-xyz"})
    assert r.status_code == 200
    sel = r.json()
    assert sel["model_id"] == "llama3"
    assert "fallback" in sel["rationale"]


async def test_usage_record_and_summary(api):
    obj_id = f"objectives:e2e-mr-{uuid.uuid4().hex[:8]}"

    r = await api.post("/model-router/usage", json={
        "objective_id": obj_id,
        "model_id": "claude-haiku-4-5",
        "provider": "anthropic",
        "input_tokens": 512,
        "output_tokens": 256,
        "cost_usd": 0.0012,
    })
    assert r.status_code == 200, r.text
    record = r.json()
    assert record["model_id"] == "claude-haiku-4-5"
    assert record["cost_usd"] == 0.0012

    # Summary (global)
    r = await api.get("/model-router/usage/summary")
    assert r.status_code == 200
    summary = r.json()
    assert "total_calls" in summary
    assert "total_cost_usd" in summary

    # Summary filtered by objective
    r = await api.get("/model-router/usage/summary", params={"objective_id": obj_id})
    assert r.status_code == 200
    obj_summary = r.json()
    assert obj_summary.get("total_calls", 0) >= 1

    # Records list
    r = await api.get("/model-router/usage/records", params={"objective_id": obj_id})
    assert r.status_code == 200
    records = r.json()
    assert any(rec["objective_id"] == obj_id for rec in records)


async def test_eval_dimensions_endpoint(api):
    r = await api.get("/eval/dimensions")
    assert r.status_code == 200
    body = r.json()
    assert body["dimensions"] == ["completeness", "logical", "evidence", "accuracy", "relevance"]
    assert body["default_threshold"] == 0.70
