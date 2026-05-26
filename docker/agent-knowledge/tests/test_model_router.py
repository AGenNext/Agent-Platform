import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.anyio
async def test_select_model(client):
    with patch("app.model_router.select_model", new=AsyncMock(return_value={
        "model_id": "llama3",
        "provider": "ollama",
        "estimated_cost": 0.0,
        "rationale": "priority=1",
    })):
        resp = await client.post("/model-router/select", json={"task_type": "research"})
    assert resp.status_code == 200
    assert resp.json()["model_id"] == "llama3"


@pytest.mark.anyio
async def test_list_routing_rules(client):
    with patch("app.model_router.list_routing_rules", new=AsyncMock(return_value=[])):
        resp = await client.get("/model-router/rules")
    assert resp.status_code == 200


@pytest.mark.anyio
async def test_record_usage(client):
    with patch("app.model_router.record_usage", new=AsyncMock(return_value={
        "id": "usage_records:1",
        "objective_id": "obj-1",
        "model_id": "llama3",
        "provider": "ollama",
        "cost_usd": 0.0,
    })):
        resp = await client.post("/model-router/usage", json={
            "objective_id": "obj-1",
            "model_id": "llama3",
            "provider": "ollama",
            "input_tokens": 100,
            "output_tokens": 50,
            "cost_usd": 0.0,
        })
    assert resp.status_code == 200


@pytest.mark.anyio
async def test_usage_summary(client):
    with patch("app.model_router.usage_summary", new=AsyncMock(return_value={
        "total_calls": 0, "total_cost_usd": 0.0
    })):
        resp = await client.get("/model-router/usage/summary")
    assert resp.status_code == 200
