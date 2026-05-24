"""
AgentPlatformClient — sync and async HTTP client for the Agent Knowledge API.

Sync:
    client = AgentPlatformClient("http://localhost:8001")
    health  = client.health()
    obj     = client.create_objective(ObjectiveCreate(title="My first objective"))
    client.run_objective(obj.id)
    model   = client.select_model("generation")
    result  = client.evaluate_artifact("artifact-id", {...})

Async:
    async with AgentPlatformClient("http://localhost:8001") as c:
        obj = await c.create_objective_async(...)
"""

from typing import Any, Dict, List, Optional
import httpx

from .models import (
    ArtifactCreate, ArtifactRecord,
    HealthStatus,
    ObjectiveCreate, ObjectiveRecord,
    RunResult,
)

_DEFAULT_TIMEOUT = 30.0


class AgentPlatformClient:
    def __init__(
        self,
        base_url: str = "http://localhost:8001",
        timeout: float = _DEFAULT_TIMEOUT,
        api_key: Optional[str] = None,
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._timeout = timeout
        self._headers: Dict[str, str] = {"Content-Type": "application/json"}
        if api_key:
            self._headers["Authorization"] = f"Bearer {api_key}"
        self._async_client: Optional[httpx.AsyncClient] = None

    # ── Context manager ──────────────────────────────────────────────────────

    async def __aenter__(self) -> "AgentPlatformClient":
        self._async_client = httpx.AsyncClient(
            base_url=self._base_url, headers=self._headers, timeout=self._timeout
        )
        return self

    async def __aexit__(self, *_) -> None:
        if self._async_client:
            await self._async_client.aclose()
            self._async_client = None

    def _sync(self) -> httpx.Client:
        return httpx.Client(base_url=self._base_url, headers=self._headers, timeout=self._timeout)

    @property
    def _async(self) -> httpx.AsyncClient:
        if not self._async_client:
            raise RuntimeError("Use 'async with AgentPlatformClient(...) as c:' for async calls")
        return self._async_client

    @staticmethod
    def _ok(r: httpx.Response) -> httpx.Response:
        r.raise_for_status()
        return r

    # ── Health ───────────────────────────────────────────────────────────────

    def health(self) -> HealthStatus:
        with self._sync() as c:
            return HealthStatus(**self._ok(c.get("/health")).json())

    async def health_async(self) -> HealthStatus:
        return HealthStatus(**self._ok(await self._async.get("/health")).json())

    # ── Objectives ───────────────────────────────────────────────────────────

    def create_objective(self, payload: ObjectiveCreate) -> ObjectiveRecord:
        with self._sync() as c:
            return ObjectiveRecord(**self._ok(c.post("/objectives", json=payload.model_dump())).json())

    async def create_objective_async(self, payload: ObjectiveCreate) -> ObjectiveRecord:
        return ObjectiveRecord(**self._ok(await self._async.post("/objectives", json=payload.model_dump())).json())

    def get_objective(self, objective_id: str) -> ObjectiveRecord:
        with self._sync() as c:
            return ObjectiveRecord(**self._ok(c.get(f"/objectives/{objective_id}")).json())

    async def get_objective_async(self, objective_id: str) -> ObjectiveRecord:
        return ObjectiveRecord(**self._ok(await self._async.get(f"/objectives/{objective_id}")).json())

    def list_objectives(self, status: Optional[str] = None, limit: int = 50) -> List[ObjectiveRecord]:
        params = {"limit": limit, **({"status": status} if status else {})}
        with self._sync() as c:
            return [ObjectiveRecord(**r) for r in self._ok(c.get("/objectives", params=params)).json()]

    async def list_objectives_async(self, status: Optional[str] = None, limit: int = 50) -> List[ObjectiveRecord]:
        params = {"limit": limit, **({"status": status} if status else {})}
        return [ObjectiveRecord(**r) for r in self._ok(await self._async.get("/objectives", params=params)).json()]

    def run_objective(self, objective_id: str) -> RunResult:
        with self._sync() as c:
            return RunResult(**self._ok(c.post(f"/objectives/{objective_id}/run")).json())

    async def run_objective_async(self, objective_id: str) -> RunResult:
        return RunResult(**self._ok(await self._async.post(f"/objectives/{objective_id}/run")).json())

    # ── Artifacts ────────────────────────────────────────────────────────────

    def create_artifact(self, payload: ArtifactCreate) -> ArtifactRecord:
        with self._sync() as c:
            return ArtifactRecord(**self._ok(c.post("/artifacts", json=payload.model_dump())).json())

    async def create_artifact_async(self, payload: ArtifactCreate) -> ArtifactRecord:
        return ArtifactRecord(**self._ok(await self._async.post("/artifacts", json=payload.model_dump())).json())

    def list_artifacts(self, objective_id: Optional[str] = None, limit: int = 50) -> List[ArtifactRecord]:
        params = {"limit": limit, **({"objective_id": objective_id} if objective_id else {})}
        with self._sync() as c:
            return [ArtifactRecord(**r) for r in self._ok(c.get("/artifacts", params=params)).json()]

    async def list_artifacts_async(self, objective_id: Optional[str] = None, limit: int = 50) -> List[ArtifactRecord]:
        params = {"limit": limit, **({"objective_id": objective_id} if objective_id else {})}
        return [ArtifactRecord(**r) for r in self._ok(await self._async.get("/artifacts", params=params)).json()]

    def get_artifact(self, artifact_id: str) -> ArtifactRecord:
        with self._sync() as c:
            return ArtifactRecord(**self._ok(c.get(f"/artifacts/{artifact_id}")).json())

    # ── Agents (Agent-Team) ──────────────────────────────────────────────────

    def create_agent(self, run_id: str, agent_role: str) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post("/agents", json={"run_id": run_id, "agent_role": agent_role})).json()

    def list_agents(self, run_id: str) -> List[Dict[str, Any]]:
        with self._sync() as c:
            return self._ok(c.get(f"/agents/run/{run_id}")).json()

    def create_handoff(self, source_agent_id: str, target_agent_id: str, context: str = "") -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post(f"/agents/{source_agent_id}/handoff", json={
                "target_agent_id": target_agent_id, "context": context
            })).json()

    def get_handoff_chain(self, agent_id: str) -> List[Dict[str, Any]]:
        with self._sync() as c:
            return self._ok(c.get(f"/agents/{agent_id}/handoff/chain")).json()

    # ── Workflows (Agent-Frameworks) ─────────────────────────────────────────

    def create_workflow_run(self, objective_id: str, initial_state: Dict[str, Any] = {}) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post("/workflows/runs", json={
                "objective_id": objective_id, "initial_state": initial_state
            })).json()

    def save_checkpoint(self, run_id: str, thread_id: str, node_id: str, state: Dict[str, Any]) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post(f"/workflows/runs/{run_id}/checkpoints", json={
                "thread_id": thread_id, "node_id": node_id, "state": state
            })).json()

    def restore_checkpoint(self, thread_id: str, checkpoint_id: Optional[str] = None) -> Dict[str, Any]:
        params = {}
        if checkpoint_id:
            params["checkpoint_id"] = checkpoint_id
        with self._sync() as c:
            return self._ok(c.get(f"/workflows/checkpoints/{thread_id}", params=params)).json()

    # ── Eval (Agent-Eval) ────────────────────────────────────────────────────

    def evaluate_artifact(
        self,
        artifact_id: str,
        dimension_scores: Dict[str, float],
        rationale: Optional[str] = None,
        threshold: float = 0.70,
    ) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post("/eval/evaluate", json={
                "artifact_id": artifact_id,
                "dimension_scores": dimension_scores,
                "rationale": rationale,
                "threshold": threshold,
            })).json()

    def get_eval_result(self, artifact_id: str) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.get(f"/eval/artifacts/{artifact_id}")).json()

    # ── Trust (Agent-Trust) ──────────────────────────────────────────────────

    def record_provenance(self, artifact_id: str, evidence_links: List[Dict[str, Any]]) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post("/trust/provenance", json={
                "artifact_id": artifact_id, "evidence_links": evidence_links
            })).json()

    def trust_gate(self, artifact_id: str, threshold: float = 0.65) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post("/trust/gate", json={
                "artifact_id": artifact_id, "threshold": threshold
            })).json()

    # ── Model Router ─────────────────────────────────────────────────────────

    def select_model(self, task_type: str, max_cost_override: Optional[float] = None) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post("/model-router/select", json={
                "task_type": task_type, "max_cost_override": max_cost_override
            })).json()

    def record_usage(
        self,
        objective_id: str,
        model_id: str,
        provider: str,
        input_tokens: int,
        output_tokens: int,
        cost_usd: float,
    ) -> Dict[str, Any]:
        with self._sync() as c:
            return self._ok(c.post("/model-router/usage", json={
                "objective_id": objective_id, "model_id": model_id,
                "provider": provider, "input_tokens": input_tokens,
                "output_tokens": output_tokens, "cost_usd": cost_usd,
            })).json()

    def usage_summary(
        self,
        objective_id: Optional[str] = None,
        model_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        params = {}
        if objective_id:
            params["objective_id"] = objective_id
        if model_id:
            params["model_id"] = model_id
        with self._sync() as c:
            return self._ok(c.get("/model-router/usage/summary", params=params)).json()
