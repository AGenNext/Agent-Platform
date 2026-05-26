import pytest
from unittest.mock import AsyncMock


@pytest.mark.anyio
async def test_create_objective(client, mock_db):
    mock_db.create = AsyncMock(return_value=[{
        "id": "objectives:1",
        "title": "Test",
        "objective_type": "generic",
        "workspace_id": None,
        "payload": {},
        "status": "pending",
        "created_at": "2026-01-01T00:00:00+00:00",
        "updated_at": "2026-01-01T00:00:00+00:00",
    }])
    resp = await client.post("/objectives", json={
        "title": "Test",
        "objective_type": "generic",
    })
    assert resp.status_code == 200
    assert resp.json()["title"] == "Test"


@pytest.mark.anyio
async def test_list_objectives(client, mock_db):
    mock_db.query = AsyncMock(return_value=[{"result": []}])
    resp = await client.get("/objectives")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


@pytest.mark.anyio
async def test_run_objective(client, mock_db):
    mock_db.merge = AsyncMock(return_value={"id": "objectives:1", "status": "running"})
    resp = await client.post("/objectives/1/run")
    assert resp.status_code == 200
    assert resp.json()["status"] == "running"
