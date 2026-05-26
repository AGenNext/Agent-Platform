#!/usr/bin/env python3
"""
End-to-end smoke test for the AGenNext Agent Platform.

Usage:
    python scripts/smoke_test.py [--base-url http://localhost:8001]

Exit code 0 = all checks passed. Non-zero = at least one failure.
"""

import argparse
import json
import sys
import time
import uuid
from typing import Any

import httpx

GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"
BOLD = "\033[1m"

passed = 0
failed = 0


def ok(label: str, detail: str = "") -> None:
    global passed
    passed += 1
    suffix = f"  {detail}" if detail else ""
    print(f"  {GREEN}✓{RESET} {label}{suffix}")


def fail(label: str, detail: str = "") -> None:
    global failed
    failed += 1
    suffix = f"  {RED}{detail}{RESET}" if detail else ""
    print(f"  {RED}✗{RESET} {label}{suffix}")


def section(title: str) -> None:
    print(f"\n{BOLD}{title}{RESET}")


def check(
    client: httpx.Client,
    method: str,
    path: str,
    label: str,
    *,
    json_body: Any = None,
    expected_status: int = 200,
    extract: str | None = None,
) -> Any:
    try:
        r = client.request(method, path, json=json_body)
        if r.status_code == expected_status:
            ok(label, f"HTTP {r.status_code}")
            if extract:
                data = r.json()
                if isinstance(data, list):
                    return data[0].get(extract) if data else None
                return data.get(extract)
            return r.json()
        else:
            fail(label, f"HTTP {r.status_code} (expected {expected_status}): {r.text[:120]}")
            return None
    except Exception as e:
        fail(label, str(e)[:120])
        return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://localhost:8001")
    args = parser.parse_args()
    base = args.base_url.rstrip("/")

    tenant = "smoke-tenant"
    agent_id = f"smoke-agent-{uuid.uuid4().hex[:8]}"
    objective_id: str | None = None
    session_id: str | None = None
    kb_id: str | None = None
    cred_id: str | None = None
    rl_config_id: str | None = None

    print(f"\n{BOLD}AGenNext Platform Smoke Test{RESET}")
    print(f"Target: {base}\n")

    with httpx.Client(base_url=base, timeout=15) as c:

        # ── 1. Health ─────────────────────────────────────────────────────
        section("1. Health")
        health = check(c, "GET", "/health", "GET /health")
        if health:
            status = health.get("status") or health.get("surrealdb")
            if status in ("ok", "healthy", True):
                ok("SurrealDB connection reported healthy")
            else:
                fail("SurrealDB health", f"unexpected value: {status}")

        openapi = check(c, "GET", "/openapi.json", "GET /openapi.json")
        if openapi and openapi.get("paths"):
            ok(f"OpenAPI schema has {len(openapi['paths'])} routes")

        # ── 2. Agent registration ─────────────────────────────────────────
        section("2. Agent Registration")
        agent_payload = {
            "agent_id": agent_id,
            "tenant_id": tenant,
            "name": "Smoke Test Agent",
            "description": "Created by smoke_test.py",
            "version": "0.0.1",
            "capabilities": [
                "reasoning", "memory", "tool_use", "code_execution",
                "web_search", "file_io", "multi_step", "self_evaluation",
            ],
            "model": "claude-sonnet-4-6",
            "tags": ["smoke", "test"],
        }
        agent = check(c, "POST", "/agents", "POST /agents (full capabilities)", json_body=agent_payload, expected_status=201)

        # Missing capability should be rejected
        bad_payload = {**agent_payload, "agent_id": f"bad-{uuid.uuid4().hex[:6]}", "capabilities": ["reasoning"]}
        r_bad = c.post("/agents", json=bad_payload)
        if r_bad.status_code in (400, 422):
            ok("POST /agents missing capabilities → 422/400 rejected")
        else:
            fail("POST /agents missing capabilities should be rejected", f"got {r_bad.status_code}")

        check(c, "GET", f"/agents/{agent_id}", "GET /agents/{id}")

        # ── 3. Memory ─────────────────────────────────────────────────────
        section("3. Memory")
        mem_payload = {
            "agent_id": agent_id,
            "tenant_id": tenant,
            "content": "The capital of France is Paris — smoke test fact.",
            "memory_type": "semantic",
            "importance": 0.9,
            "tags": ["geo", "smoke"],
        }
        check(c, "POST", "/memory/store", "POST /memory/store", json_body=mem_payload, expected_status=201)

        time.sleep(0.3)  # let indexing settle
        search_res = check(c, "GET", f"/memory/{agent_id}/search?q=capital+France&limit=3", "GET /memory search")
        if search_res and isinstance(search_res, list) and len(search_res) > 0:
            ok(f"Memory recall returned {len(search_res)} result(s)")
        elif search_res is not None:
            fail("Memory search returned empty list")

        # ── 4. Objectives ─────────────────────────────────────────────────
        section("4. Objectives")
        obj_payload = {
            "tenant_id": tenant,
            "agent_id": agent_id,
            "title": "Smoke Test Objective",
            "description": "Verify the platform is operational.",
            "priority": "medium",
        }
        obj = check(c, "POST", "/objectives", "POST /objectives", json_body=obj_payload, expected_status=201)
        if obj:
            objective_id = obj.get("objective_id") or obj.get("id")
        check(c, "GET", f"/objectives?tenant_id={tenant}", "GET /objectives list")

        # ── 5. Tasks ──────────────────────────────────────────────────────
        section("5. Tasks")
        task_payload = {
            "tenant_id": tenant,
            "agent_id": agent_id,
            "objective_id": objective_id,
            "title": "Smoke sub-task",
            "task_type": "analysis",
        }
        task = check(c, "POST", "/tasks", "POST /tasks", json_body=task_payload, expected_status=201)
        task_id = None
        if task:
            task_id = task.get("task_id") or task.get("id")
        if task_id:
            check(c, "PATCH", f"/tasks/{task_id}/complete",
                  "PATCH /tasks/{id}/complete",
                  json_body={"result": "smoke ok"},
                  expected_status=200)

        # ── 6. Artifacts ──────────────────────────────────────────────────
        section("6. Artifacts")
        art_payload = {
            "tenant_id": tenant,
            "agent_id": agent_id,
            "objective_id": objective_id,
            "title": "Smoke Report",
            "artifact_type": "report",
            "content": "Platform is operational.",
            "format": "text",
        }
        art = check(c, "POST", "/artifacts", "POST /artifacts", json_body=art_payload, expected_status=201)
        art_id = None
        if art:
            art_id = art.get("artifact_id") or art.get("id")
        if art_id:
            eval_payload = {
                "correct": 0.9, "logical": 0.9, "evidence": 0.8,
                "aligned": 0.95, "readable": 0.95,
                "evaluator_agent_id": agent_id,
            }
            check(c, "POST", f"/artifacts/{art_id}/evaluate", "POST /artifacts/{id}/evaluate",
                  json_body=eval_payload, expected_status=200)

        # ── 7. Sessions ───────────────────────────────────────────────────
        section("7. Sessions")
        sess_payload = {"tenant_id": tenant, "agent_id": agent_id, "channel": "smoke_test"}
        sess = check(c, "POST", "/sessions/", "POST /sessions/", json_body=sess_payload, expected_status=201)
        if sess:
            session_id = sess.get("session_id") or sess.get("id")
        if session_id:
            msg = {"role": "user", "content": "Hello from smoke test"}
            check(c, "POST", f"/sessions/{session_id}/messages", "POST /sessions/{id}/messages",
                  json_body=msg, expected_status=201)
            check(c, "GET", f"/sessions/{session_id}/messages", "GET /sessions/{id}/messages")

        # ── 8. Knowledge Base ─────────────────────────────────────────────
        section("8. Knowledge Base")
        kb_payload = {
            "tenant_id": tenant,
            "name": "Smoke KB",
            "description": "Smoke test knowledge base",
            "embedding_model": "text-embedding-3-small",
        }
        kb = check(c, "POST", "/knowledge/", "POST /knowledge/ (create KB)", json_body=kb_payload, expected_status=201)
        if kb:
            kb_id = kb.get("kb_id") or kb.get("id")
        if kb_id:
            doc_payload = {
                "kb_id": kb_id,
                "title": "Smoke Doc",
                "content": "The AGenNext platform uses SurrealDB as its primary runtime.",
                "source_url": "https://example.com/smoke",
                "tenant_id": tenant,
            }
            check(c, "POST", "/knowledge/ingest", "POST /knowledge/ingest",
                  json_body=doc_payload, expected_status=201)
            time.sleep(0.2)
            check(c, "GET", f"/knowledge/search?q=SurrealDB+runtime&tenant_id={tenant}",
                  "GET /knowledge/search")

        # ── 9. Credentials ────────────────────────────────────────────────
        section("9. Credentials (write-only vault)")
        cred_payload = {
            "tenant_id": tenant,
            "name": "Smoke API Key",
            "provider": "anthropic",
            "credential_type": "api_key",
            "secret": "sk-smoke-test-secret-never-returned",
            "scopes": ["read"],
        }
        cred = check(c, "POST", "/credentials/", "POST /credentials/", json_body=cred_payload, expected_status=201)
        if cred:
            cred_id = cred.get("cred_id") or cred.get("id")
        if cred_id:
            cred_get = check(c, "GET", f"/credentials/{cred_id}", "GET /credentials/{id} (metadata only)")
            if cred_get and "secret" not in cred_get:
                ok("Secret field absent from GET response (write-only enforced)")
            elif cred_get:
                fail("Secret field PRESENT in GET response — write-only not enforced")

        # ── 10. Rate Limits ───────────────────────────────────────────────
        section("10. Rate Limits")
        rl_payload = {
            "tenant_id": tenant,
            "resource": "llm_calls",
            "limit": 1000,
            "window": "1h",
            "scope": "tenant",
        }
        rl = check(c, "POST", "/rate-limits/configs", "POST /rate-limits/configs",
                   json_body=rl_payload, expected_status=201)
        if rl:
            rl_config_id = rl.get("config_id") or rl.get("id")
        check(c, "GET", f"/rate-limits/configs?tenant_id={tenant}", "GET /rate-limits/configs list")
        check_payload = {"tenant_id": tenant, "resource": "llm_calls", "requested": 1}
        check(c, "POST", "/rate-limits/check", "POST /rate-limits/check", json_body=check_payload)

        # ── 11. Alert Rules ───────────────────────────────────────────────
        section("11. Alert Rules")
        alert_payload = {
            "tenant_id": tenant,
            "name": "Smoke High Cost Alert",
            "metric": "cost_usd",
            "condition": "gt",
            "threshold": 99999.0,
            "window": "1h",
            "severity": "warning",
            "cooldown_minutes": 60,
        }
        check(c, "POST", "/alerts/rules", "POST /alerts/rules", json_body=alert_payload, expected_status=201)
        check(c, "GET", f"/alerts/rules?tenant_id={tenant}", "GET /alerts/rules list")
        check(c, "POST", "/alerts/evaluate", "POST /alerts/evaluate (manual trigger)", json_body={"tenant_id": tenant})

        # ── 12. Observability ─────────────────────────────────────────────
        section("12. Observability")
        metric_payload = {
            "tenant_id": tenant,
            "agent_id": agent_id,
            "metric": "llm_calls",
            "value": 5.0,
            "unit": "count",
        }
        check(c, "POST", "/observability/metrics", "POST /observability/metrics",
              json_body=metric_payload, expected_status=201)
        check(c, "GET", f"/observability/metrics/summary?tenant_id={tenant}", "GET /observability/metrics/summary")
        check(c, "GET", "/observability/views/agent-status", "GET /observability/views/agent-status")
        check(c, "GET", "/observability/views/daily-spend", "GET /observability/views/daily-spend")

        # ── 13. Traces ────────────────────────────────────────────────────
        section("13. Traces")
        trace_id = uuid.uuid4().hex
        span_payload = {
            "tenant_id": tenant,
            "agent_id": agent_id,
            "trace_id": trace_id,
            "span_id": uuid.uuid4().hex[:16],
            "operation": "smoke_test.run",
            "status": "ok",
            "duration_ms": 42,
        }
        check(c, "POST", "/traces", "POST /traces", json_body=span_payload, expected_status=201)
        check(c, "GET", f"/traces?trace_id={trace_id}", "GET /traces by trace_id")

        # ── 14. Billing ───────────────────────────────────────────────────
        section("14. Billing")
        usage_payload = {
            "tenant_id": tenant,
            "agent_id": agent_id,
            "model": "claude-sonnet-4-6",
            "input_tokens": 100,
            "output_tokens": 50,
            "cost_usd": 0.001,
            "objective_id": objective_id,
        }
        check(c, "POST", "/billing/usage", "POST /billing/usage", json_body=usage_payload, expected_status=201)
        check(c, "GET", f"/billing/usage?tenant_id={tenant}", "GET /billing/usage list")
        check(c, "GET", f"/billing/summary?tenant_id={tenant}", "GET /billing/summary")

        # ── 15. Trust ─────────────────────────────────────────────────────
        section("15. Trust")
        trust_payload = {
            "agent_id": agent_id,
            "tenant_id": tenant,
            "score": 0.88,
            "rationale": "Smoke test high trust",
            "dimensions": {"correct": 0.9, "logical": 0.9, "evidence": 0.8, "aligned": 0.9, "readable": 0.85},
        }
        check(c, "POST", "/trust/scores", "POST /trust/scores", json_body=trust_payload, expected_status=201)
        check(c, "GET", f"/trust/scores/{agent_id}", "GET /trust/scores/{agent_id}")

    # ── Summary ───────────────────────────────────────────────────────────
    total = passed + failed
    print(f"\n{'─' * 50}")
    print(f"{BOLD}Results: {GREEN}{passed} passed{RESET}{BOLD}, {RED}{failed} failed{RESET}{BOLD} / {total} total{RESET}")
    if failed == 0:
        print(f"{GREEN}{BOLD}All checks passed — platform is healthy.{RESET}")
    else:
        print(f"{RED}{BOLD}{failed} check(s) failed — see output above.{RESET}")
    print()
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
