import pytest
from unittest.mock import AsyncMock


@pytest.mark.anyio
async def test_create_artifact(client, mock_db):
    mock_db.create = AsyncMock(return_value=[{
        "id": "artifacts:1",
        "objective_id": "objectives:1",
        "artifact_type": "document",
        "title": "Doc",
        "content_ref": "s3://bucket/key",
        "payload": {},
        "status": "draft",
        "eval_status": None,
        "trust_status": None,
        "created_at": "2026-01-01T00:00:00+00:00",
    }])
    resp = await client.post("/artifacts", json={
        "objective_id": "objectives:1",
        "artifact_type": "document",
        "title": "Doc",
        "content_ref": "s3://bucket/key",
    })
    assert resp.status_code == 200
    assert resp.json()["title"] == "Doc"


@pytest.mark.anyio
async def test_list_artifacts(client, mock_db):
    mock_db.query = AsyncMock(return_value=[{"result": []}])
    resp = await client.get("/artifacts")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
