import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.anyio
async def test_evaluate_artifact(client):
    with patch("app.eval.evaluate_artifact", new=AsyncMock(return_value={
        "id": "eval_results:1",
        "artifact_id": "artifacts:1",
        "composite_score": 0.85,
        "passed": True,
        "threshold": 0.70,
    })):
        resp = await client.post("/eval/evaluate", json={
            "artifact_id": "artifacts:1",
            "dimension_scores": {
                "completeness": 0.9,
                "logical": 0.8,
                "evidence": 0.85,
                "accuracy": 0.8,
                "relevance": 0.9,
            },
        })
    assert resp.status_code == 200
    assert resp.json()["passed"] is True


@pytest.mark.anyio
async def test_eval_dimensions(client):
    resp = await client.get("/eval/dimensions")
    assert resp.status_code == 200
    assert "dimensions" in resp.json()
