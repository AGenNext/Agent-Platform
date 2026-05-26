import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.anyio
async def test_create_run(client):
    with patch("app.frameworks.create_run", new=AsyncMock(return_value={
        "id": "workflow_runs:1",
        "objective_id": "obj-1",
        "status": "running",
    })):
        resp = await client.post("/workflows/runs", json={
            "objective_id": "obj-1",
            "initial_state": {},
        })
    assert resp.status_code == 200
    assert resp.json()["status"] == "running"
