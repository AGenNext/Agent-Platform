import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.anyio
async def test_record_provenance(client):
    with patch("app.trust.record_provenance", new=AsyncMock(return_value={
        "id": "trust_scores:1",
        "artifact_id": "artifacts:1",
        "score": 0.80,
        "verified": True,
    })):
        resp = await client.post("/trust/provenance", json={
            "artifact_id": "artifacts:1",
            "evidence_links": [
                {"source_ref": "https://example.com/doc", "extract": "key claim", "step_description": "research"}
            ],
        })
    assert resp.status_code == 200
    assert resp.json()["verified"] is True


@pytest.mark.anyio
async def test_trust_gate(client):
    with patch("app.trust.trust_gate", new=AsyncMock(return_value={
        "passed": True, "score": 0.80, "verified": True, "threshold": 0.65, "reason": "ok"
    })):
        resp = await client.post("/trust/gate", json={"artifact_id": "artifacts:1"})
    assert resp.status_code == 200
    assert resp.json()["passed"] is True
