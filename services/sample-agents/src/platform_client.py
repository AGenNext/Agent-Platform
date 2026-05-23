"""
Thin client wrapping agent-knowledge-api.
Agents use this to register, store memory, log traces, and emit usage records.
"""
import os
import time
import uuid
from typing import Any

import httpx

API_BASE = os.getenv("PLATFORM_API_URL", "http://localhost:8000")
TENANT_ID = os.getenv("PLATFORM_TENANT_ID", "tenant-demo")


class PlatformClient:
    def __init__(self, base_url: str = API_BASE, tenant_id: str = TENANT_ID):
        self.base = base_url.rstrip("/")
        self.tenant_id = tenant_id
        self._http = httpx.Client(timeout=30)

    def _post(self, path: str, body: dict) -> dict:
        r = self._http.post(f"{self.base}{path}", json=body)
        r.raise_for_status()
        return r.json()

    def _get(self, path: str, params: dict | None = None) -> Any:
        r = self._http.get(f"{self.base}{path}", params=params or {})
        r.raise_for_status()
        return r.json()

    # ── Agent registration ──────────────────────────────────────────────────

    def register_agent(
        self,
        name: str,
        description: str,
        version: str = "1.0.0",
        goal_types: list[str] | None = None,
        skill_ids: list[str] | None = None,
    ) -> dict:
        return self._post("/agents/register", {
            "name": name,
            "description": description,
            "version": version,
            "tenant_id": self.tenant_id,
            "goal_types": goal_types or [],
            "skill_ids": skill_ids or [],
            "capabilities": {
                "can_plan": True,
                "can_execute": True,
                "can_reflect": True,
                "can_learn": True,
                "can_communicate": True,
                "can_use_tools": True,
                "can_self_evaluate": True,
                "can_coordinate": True,
            },
        })

    # ── Memory ──────────────────────────────────────────────────────────────

    def store_memory(
        self,
        agent_id: str,
        content: str,
        memory_type: str = "episodic",
        importance: float = 0.5,
        tags: list[str] | None = None,
    ) -> dict:
        return self._post("/memory/", {
            "agent_id": agent_id,
            "tenant_id": self.tenant_id,
            "content": content,
            "memory_type": memory_type,
            "importance": importance,
            "tags": tags or [],
        })

    def search_memory(
        self,
        agent_id: str,
        query: str,
        limit: int = 5,
        memory_type: str | None = None,
    ) -> list[dict]:
        body: dict = {
            "agent_id": agent_id,
            "tenant_id": self.tenant_id,
            "query": query,
            "limit": limit,
        }
        if memory_type:
            body["memory_type"] = memory_type
        return self._post("/memory/search", body)

    # ── Objectives & tasks ──────────────────────────────────────────────────

    def run_objective(self, goal: str, context: dict | None = None, priority: int = 5) -> dict:
        return self._post("/objectives/run", {
            "goal": goal,
            "context": context or {},
            "priority": priority,
        })

    def create_task(self, objective_id: str, agent_id: str, name: str, description: str = "") -> dict:
        return self._post("/tasks/", {
            "objective_id": objective_id,
            "agent_id": agent_id,
            "tenant_id": self.tenant_id,
            "name": name,
            "description": description,
        })

    def complete_task(self, task_id: str, output: dict | None = None) -> dict:
        return self._post(f"/tasks/{task_id}/status", {
            "status": "completed",
            "output": output or {},
        })

    def fail_task(self, task_id: str, error: str) -> dict:
        return self._post(f"/tasks/{task_id}/status", {
            "status": "failed",
            "error": error,
        })

    # ── Artifacts ───────────────────────────────────────────────────────────

    def create_artifact(
        self,
        objective_id: str,
        agent_id: str,
        name: str,
        text: str,
        schema_type: str = "CreativeWork",
        format: str = "text/markdown",
    ) -> dict:
        return self._post("/artifacts/", {
            "objective_id": objective_id,
            "agent_id": agent_id,
            "tenant_id": self.tenant_id,
            "name": name,
            "text": text,
            "schema_type": schema_type,
            "format": format,
        })

    # ── Trust evaluation ────────────────────────────────────────────────────

    def evaluate_artifact(
        self,
        artifact_id: str,
        agent_id: str,
        correct: float,
        logical: float,
        evidence: float,
        aligned: float,
        readable: float,
        notes: str = "",
    ) -> dict:
        return self._post("/trust/evaluate", {
            "artifact_id": artifact_id,
            "agent_id": agent_id,
            "tenant_id": self.tenant_id,
            "correct": correct,
            "logical": logical,
            "evidence": evidence,
            "aligned": aligned,
            "readable": readable,
            "notes": notes,
        })

    # ── Traces ──────────────────────────────────────────────────────────────

    def trace(
        self,
        objective_id: str,
        agent_id: str,
        event_type: str,
        payload: dict | None = None,
        trace_id: str | None = None,
        parent_span_id: str | None = None,
        duration_ms: int | None = None,
    ) -> dict:
        return self._post("/traces/", {
            "objective_id": objective_id,
            "agent_id": agent_id,
            "event_type": event_type,
            "payload": payload or {},
            "trace_id": trace_id,
            "parent_span_id": parent_span_id,
            "duration_ms": duration_ms,
        })

    # ── Billing ─────────────────────────────────────────────────────────────

    def log_usage(
        self,
        agent_id: str,
        objective_id: str,
        model_id: str,
        tokens_in: int,
        tokens_out: int,
        cost_usd: float,
        provider: str = "anthropic",
    ) -> dict:
        return self._post("/billing/usage", {
            "agent_id": agent_id,
            "objective_id": objective_id,
            "tenant_id": self.tenant_id,
            "model_id": model_id,
            "provider": provider,
            "tokens_in": tokens_in,
            "tokens_out": tokens_out,
            "cost_usd": cost_usd,
        })

    # ── Helpers ─────────────────────────────────────────────────────────────

    @staticmethod
    def new_trace_id() -> str:
        return uuid.uuid4().hex

    def health(self) -> bool:
        try:
            r = self._get("/health")
            return r.get("db") == "ok"
        except Exception:
            return False

    def close(self):
        self._http.close()

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()
