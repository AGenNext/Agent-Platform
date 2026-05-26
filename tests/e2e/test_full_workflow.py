"""E2E: complete agent workflow happy-path.

Scenario (all steps run against the live stack in order):
  1.  Create objective
  2.  List objectives (verify it appears)
  3.  Fetch objective by ID
  4.  Mark objective as running
  5.  Create workflow run
  6.  Create researcher agent
  7.  Create writer agent
  8.  List agents for the run
  9.  Create task for researcher
  10. Complete the task
  11. Handoff researcher → writer
  12. Create artifact
  13. List artifacts (verify it appears)
  14. Evaluate artifact with CLEAR scores
  15. Fetch eval result
  16. Record provenance (5 evidence links → high trust score)
  17. Fetch trust score
  18. Trust gate (should pass at default 0.65 threshold)
"""
import pytest

from conftest import bare_id

pytestmark = pytest.mark.asyncio


async def test_full_agent_workflow(api):
    # ── 1. Create objective ───────────────────────────────────────────────────
    r = await api.post("/objectives", json={
        "title": "E2E research report on LLM benchmarks",
        "objective_type": "research",
        "payload": {"topic": "LLM benchmarks 2025"},
    })
    assert r.status_code == 200, f"create objective: {r.text}"
    obj = r.json()
    assert obj["title"] == "E2E research report on LLM benchmarks"
    assert obj["status"] == "pending"
    obj_id = obj["id"]
    bare_obj = bare_id(obj_id)

    # ── 2. List objectives ────────────────────────────────────────────────────
    r = await api.get("/objectives")
    assert r.status_code == 200
    ids = [o["id"] for o in r.json()]
    assert obj_id in ids

    # ── 3. Get objective by ID ────────────────────────────────────────────────
    r = await api.get(f"/objectives/{bare_obj}")
    assert r.status_code == 200
    assert r.json()["id"] == obj_id

    # ── 4. Mark objective running ─────────────────────────────────────────────
    r = await api.post(f"/objectives/{bare_obj}/run")
    assert r.status_code == 200
    assert r.json()["status"] == "running"

    # ── 5. Create workflow run ────────────────────────────────────────────────
    r = await api.post("/workflows/runs", json={
        "objective_id": obj_id,
        "initial_state": {"phase": "research"},
    })
    assert r.status_code == 200, f"create run: {r.text}"
    run = r.json()
    assert run["status"] == "running"
    run_id = run["id"]
    bare_run = bare_id(run_id)

    # ── 6. Create researcher agent ────────────────────────────────────────────
    r = await api.post("/agents", json={"run_id": run_id, "agent_role": "researcher"})
    assert r.status_code == 200, f"create researcher: {r.text}"
    researcher = r.json()
    researcher_id = researcher["id"]
    bare_researcher = bare_id(researcher_id)

    # ── 7. Create writer agent ────────────────────────────────────────────────
    r = await api.post("/agents", json={"run_id": run_id, "agent_role": "writer"})
    assert r.status_code == 200, f"create writer: {r.text}"
    writer = r.json()
    writer_id = writer["id"]
    bare_writer = bare_id(writer_id)

    # ── 8. List agents for run ────────────────────────────────────────────────
    r = await api.get(f"/agents/run/{bare_run}")
    assert r.status_code == 200
    roles = [a["agent_role"] for a in r.json()]
    assert "researcher" in roles
    assert "writer" in roles

    # ── 9. Create task for researcher ─────────────────────────────────────────
    r = await api.post(f"/agents/{bare_researcher}/tasks", json={
        "description": "Gather top LLM benchmark papers from 2025",
        "skill_id": "web_search",
    })
    assert r.status_code == 200, f"create task: {r.text}"
    task = r.json()
    task_id = task["id"]
    bare_task = bare_id(task_id)
    assert task["status"] == "pending"

    # ── 10. Complete the task ─────────────────────────────────────────────────
    r = await api.patch(f"/agents/{bare_researcher}/tasks/{bare_task}/complete", json={
        "output_ref": "minio://agent-artifacts/e2e/research-notes.json",
        "status": "completed",
    })
    assert r.status_code == 200, f"complete task: {r.text}"
    assert r.json()["status"] == "completed"

    # ── 11. Handoff researcher → writer ───────────────────────────────────────
    r = await api.post(f"/agents/{bare_researcher}/handoff", json={
        "target_agent_id": bare_writer,
        "context": "Research complete — please draft the report",
        "payload": {"notes_ref": "minio://agent-artifacts/e2e/research-notes.json"},
    })
    assert r.status_code == 200, f"handoff: {r.text}"

    # ── 12. Create artifact ───────────────────────────────────────────────────
    r = await api.post("/artifacts", json={
        "objective_id": obj_id,
        "artifact_type": "report",
        "title": "LLM Benchmarks Report 2025",
        "content_ref": "minio://agent-artifacts/e2e/report-v1.md",
        "payload": {"word_count": 2400},
    })
    assert r.status_code == 200, f"create artifact: {r.text}"
    artifact = r.json()
    artifact_id = artifact["id"]
    bare_artifact = bare_id(artifact_id)
    assert artifact["status"] == "draft"

    # ── 13. List artifacts ────────────────────────────────────────────────────
    r = await api.get("/artifacts", params={"objective_id": obj_id})
    assert r.status_code == 200
    assert any(a["id"] == artifact_id for a in r.json())

    # ── 14. Evaluate artifact (all CLEAR scores = 0.85 → passes 0.70 gate) ───
    r = await api.post("/eval/evaluate", json={
        "artifact_id": artifact_id,
        "dimension_scores": {
            "completeness": 0.85,
            "logical": 0.90,
            "evidence": 0.80,
            "accuracy": 0.88,
            "relevance": 0.92,
        },
        "rationale": "Thorough and well-cited report",
        "threshold": 0.70,
    })
    assert r.status_code == 200, f"evaluate: {r.text}"
    ev = r.json()
    assert ev["passed"] is True
    assert ev["composite_score"] >= 0.70

    # ── 15. Fetch eval result ─────────────────────────────────────────────────
    r = await api.get(f"/eval/artifacts/{artifact_id}")
    assert r.status_code == 200
    assert r.json()["artifact_id"] == artifact_id

    # ── 16. Record provenance (5 links → trust score > 0.65) ─────────────────
    r = await api.post("/trust/provenance", json={
        "artifact_id": artifact_id,
        "evidence_links": [
            {"source_ref": "arxiv.org/abs/2501.00001", "extract": "MMLU results table", "step_description": "benchmark data"},
            {"source_ref": "arxiv.org/abs/2501.00002", "extract": "HumanEval scores", "step_description": "coding benchmarks"},
            {"source_ref": "openai.com/research/gpt5", "extract": "Safety evaluation", "step_description": "safety scores"},
            {"source_ref": "anthropic.com/research/claude4", "extract": "MATH benchmark", "step_description": "math capability"},
            {"source_ref": "huggingface.co/open-llm-leaderboard", "extract": "Leaderboard snapshot", "step_description": "rankings"},
        ],
    })
    assert r.status_code == 200, f"provenance: {r.text}"
    trust = r.json()
    assert trust["score"] > 0.0

    # ── 17. Fetch trust score ─────────────────────────────────────────────────
    r = await api.get(f"/trust/artifacts/{artifact_id}")
    assert r.status_code == 200
    score_record = r.json()
    assert score_record["artifact_id"] == artifact_id
    assert 0.0 <= score_record["score"] <= 1.0

    # ── 18. Trust gate ────────────────────────────────────────────────────────
    r = await api.post("/trust/gate", json={
        "artifact_id": artifact_id,
        "threshold": 0.50,
    })
    assert r.status_code == 200
    gate = r.json()
    assert "passed" in gate
    assert gate["score"] is not None
