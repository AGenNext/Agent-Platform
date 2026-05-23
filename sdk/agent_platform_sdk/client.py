"""
AgentPlatformClient — sync and async HTTP client for the Agent Knowledge API.

Sync usage:
    from agent_platform_sdk import AgentPlatformClient, ObjectiveCreate

    client = AgentPlatformClient("http://localhost:8001")
    health = client.health()
    objective = client.create_objective(ObjectiveCreate(title="My objective"))
    client.run_objective(objective.id)

Async usage:
    async with AgentPlatformClient("http://localhost:8001") as client:
        health = await client.health_async()
        objective = await client.create_objective_async(ObjectiveCreate(title="My objective"))
"""

from typing import List, Optional

import httpx

from .models import (
    ArtifactCreate,
    ArtifactRecord,
    HealthStatus,
    ObjectiveCreate,
    ObjectiveRecord,
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
        self._headers = {"Content-Type": "application/json"}
        if api_key:
            self._headers["Authorization"] = f"Bearer {api_key}"
        self._async_client: Optional[httpx.AsyncClient] = None

    # ── Context manager (async) ──────────────────────────────────────────────

    async def __aenter__(self) -> "AgentPlatformClient":
        self._async_client = httpx.AsyncClient(
            base_url=self._base_url,
            headers=self._headers,
            timeout=self._timeout,
        )
        return self

    async def __aexit__(self, *_) -> None:
        if self._async_client:
            await self._async_client.aclose()
            self._async_client = None

    # ── Internal helpers ─────────────────────────────────────────────────────

    def _sync(self) -> httpx.Client:
        return httpx.Client(
            base_url=self._base_url,
            headers=self._headers,
            timeout=self._timeout,
        )

    @property
    def _async(self) -> httpx.AsyncClient:
        if self._async_client is None:
            raise RuntimeError("Use 'async with AgentPlatformClient(...) as client:' for async calls")
        return self._async_client

    @staticmethod
    def _raise(response: httpx.Response) -> httpx.Response:
        response.raise_for_status()
        return response

    # ── Health ───────────────────────────────────────────────────────────────

    def health(self) -> HealthStatus:
        with self._sync() as c:
            return HealthStatus(**self._raise(c.get("/health")).json())

    async def health_async(self) -> HealthStatus:
        return HealthStatus(**self._raise(await self._async.get("/health")).json())

    # ── Objectives ───────────────────────────────────────────────────────────

    def create_objective(self, payload: ObjectiveCreate) -> ObjectiveRecord:
        with self._sync() as c:
            return ObjectiveRecord(**self._raise(
                c.post("/objectives", json=payload.model_dump())
            ).json())

    async def create_objective_async(self, payload: ObjectiveCreate) -> ObjectiveRecord:
        return ObjectiveRecord(**self._raise(
            await self._async.post("/objectives", json=payload.model_dump())
        ).json())

    def get_objective(self, objective_id: str) -> ObjectiveRecord:
        with self._sync() as c:
            return ObjectiveRecord(**self._raise(
                c.get(f"/objectives/{objective_id}")
            ).json())

    async def get_objective_async(self, objective_id: str) -> ObjectiveRecord:
        return ObjectiveRecord(**self._raise(
            await self._async.get(f"/objectives/{objective_id}")
        ).json())

    def list_objectives(
        self,
        status: Optional[str] = None,
        limit: int = 50,
    ) -> List[ObjectiveRecord]:
        params = {"limit": limit}
        if status:
            params["status"] = status
        with self._sync() as c:
            return [ObjectiveRecord(**r) for r in self._raise(
                c.get("/objectives", params=params)
            ).json()]

    async def list_objectives_async(
        self,
        status: Optional[str] = None,
        limit: int = 50,
    ) -> List[ObjectiveRecord]:
        params = {"limit": limit}
        if status:
            params["status"] = status
        return [ObjectiveRecord(**r) for r in self._raise(
            await self._async.get("/objectives", params=params)
        ).json()]

    def run_objective(self, objective_id: str) -> RunResult:
        with self._sync() as c:
            return RunResult(**self._raise(
                c.post(f"/objectives/{objective_id}/run")
            ).json())

    async def run_objective_async(self, objective_id: str) -> RunResult:
        return RunResult(**self._raise(
            await self._async.post(f"/objectives/{objective_id}/run")
        ).json())

    # ── Artifacts ────────────────────────────────────────────────────────────

    def create_artifact(self, payload: ArtifactCreate) -> ArtifactRecord:
        with self._sync() as c:
            return ArtifactRecord(**self._raise(
                c.post("/artifacts", json=payload.model_dump())
            ).json())

    async def create_artifact_async(self, payload: ArtifactCreate) -> ArtifactRecord:
        return ArtifactRecord(**self._raise(
            await self._async.post("/artifacts", json=payload.model_dump())
        ).json())

    def list_artifacts(
        self,
        objective_id: Optional[str] = None,
        limit: int = 50,
    ) -> List[ArtifactRecord]:
        params = {"limit": limit}
        if objective_id:
            params["objective_id"] = objective_id
        with self._sync() as c:
            return [ArtifactRecord(**r) for r in self._raise(
                c.get("/artifacts", params=params)
            ).json()]

    async def list_artifacts_async(
        self,
        objective_id: Optional[str] = None,
        limit: int = 50,
    ) -> List[ArtifactRecord]:
        params = {"limit": limit}
        if objective_id:
            params["objective_id"] = objective_id
        return [ArtifactRecord(**r) for r in self._raise(
            await self._async.get("/artifacts", params=params)
        ).json()]

    def get_artifact(self, artifact_id: str) -> ArtifactRecord:
        with self._sync() as c:
            return ArtifactRecord(**self._raise(
                c.get(f"/artifacts/{artifact_id}")
            ).json())

    async def get_artifact_async(self, artifact_id: str) -> ArtifactRecord:
        return ArtifactRecord(**self._raise(
            await self._async.get(f"/artifacts/{artifact_id}")
        ).json())
