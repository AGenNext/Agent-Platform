"""E2E: workflow run lifecycle and checkpoint store."""
import uuid
import pytest

from conftest import bare_id

pytestmark = pytest.mark.asyncio


async def test_run_lifecycle(api):
    obj_id = f"objectives:e2e-wf-{uuid.uuid4().hex[:8]}"

    # Create run
    r = await api.post("/workflows/runs", json={
        "objective_id": obj_id,
        "initial_state": {"step": 0, "data": []},
    })
    assert r.status_code == 200, r.text
    run = r.json()
    assert run["status"] == "running"
    run_id = run["id"]
    bare_run = bare_id(run_id)

    # Fetch run
    r = await api.get(f"/workflows/runs/{bare_run}")
    assert r.status_code == 200
    assert r.json()["id"] == run_id

    # List runs for objective
    r = await api.get(f"/workflows/objective/{obj_id}/runs")
    assert r.status_code == 200
    assert any(rr["id"] == run_id for rr in r.json())

    # Update state
    r = await api.patch(f"/workflows/runs/{bare_run}/state", json={
        "state": {"step": 1, "data": ["item-a"]},
        "status": "running",
    })
    assert r.status_code == 200

    # Complete run
    r = await api.post(f"/workflows/runs/{bare_run}/complete", json={
        "state": {"step": 2, "data": ["item-a", "item-b"]},
    })
    assert r.status_code == 200
    assert r.json()["status"] == "completed"


async def test_run_failure(api):
    obj_id = f"objectives:e2e-fail-{uuid.uuid4().hex[:8]}"

    r = await api.post("/workflows/runs", json={"objective_id": obj_id})
    assert r.status_code == 200
    bare_run = bare_id(r.json()["id"])

    r = await api.post(f"/workflows/runs/{bare_run}/fail", params={"error": "out of memory"})
    assert r.status_code == 200
    assert r.json()["status"] == "failed"


async def test_checkpoint_save_and_restore(api):
    obj_id = f"objectives:e2e-ckpt-{uuid.uuid4().hex[:8]}"
    thread_id = f"thread-{uuid.uuid4().hex[:8]}"

    r = await api.post("/workflows/runs", json={"objective_id": obj_id})
    assert r.status_code == 200
    bare_run = bare_id(r.json()["id"])

    # Save checkpoint
    r = await api.post(f"/workflows/runs/{bare_run}/checkpoints", json={
        "thread_id": thread_id,
        "node_id": "step_research",
        "state": {"gathered_sources": 12, "tokens_used": 4096},
        "metadata": {"phase": "research"},
    })
    assert r.status_code == 200, r.text
    body = r.json()
    assert "checkpoint_id" in body
    assert body["thread_id"] == thread_id

    # Restore latest checkpoint
    r = await api.get(f"/workflows/checkpoints/{thread_id}")
    assert r.status_code == 200
    restored = r.json()
    assert restored["channel_values"]["gathered_sources"] == 12

    # List checkpoints
    r = await api.get(f"/workflows/checkpoints/{thread_id}/list")
    assert r.status_code == 200
    assert len(r.json()) >= 1
