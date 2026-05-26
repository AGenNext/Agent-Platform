import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.anyio
async def test_create_agent(client):
    with patch("app.agent_team.create_agent", new=AsyncMock(return_value={
        "id": "agents:1", "agent_role": "researcher", "run_id": "run-1", "status": "idle"
    })):
        resp = await client.post("/agents", json={"run_id": "run-1", "agent_role": "researcher"})
    assert resp.status_code == 200
    assert resp.json()["agent_role"] == "researcher"


@pytest.mark.anyio
async def test_list_agents_by_run(client):
    with patch("app.agent_team.list_agents", new=AsyncMock(return_value=[])):
        resp = await client.get("/agents/run/run-1")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
