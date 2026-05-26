"""
Agent-to-Agent (A2A) demo.

Pattern: a Coordinator agent breaks a task into sub-tasks, dispatches them
to Worker agents via the platform's /tasks API, then polls for results and
synthesises a final answer.  Both roles run in the same process for the demo;
in production each would be a separate deployed service.

Usage:
    python src/a2a_agent.py
"""

from __future__ import annotations

import asyncio
import time
import uuid
from dataclasses import dataclass, field
from typing import Any

import httpx
from platform_client import PlatformClient

TENANT = "a2a-demo"
COORD_ID = f"coordinator-{uuid.uuid4().hex[:6]}"
WORKER_IDS = [f"worker-{uuid.uuid4().hex[:6]}" for _ in range(3)]
CAPABILITIES = [
    "reasoning", "memory", "tool_use", "code_execution",
    "web_search", "file_io", "multi_step", "self_evaluation",
]


# ── Agent stubs ──────────────────────────────────────────────────────────────

@dataclass
class Message:
    sender: str
    recipient: str
    task_id: str
    payload: dict[str, Any]
    reply: asyncio.Future[dict[str, Any]] = field(default_factory=asyncio.get_event_loop().create_future)


class A2AMessageBus:
    """In-process async message bus that mimics a real A2A transport."""

    def __init__(self) -> None:
        self._queues: dict[str, asyncio.Queue[Message]] = {}

    def register(self, agent_id: str) -> asyncio.Queue[Message]:
        q: asyncio.Queue[Message] = asyncio.Queue()
        self._queues[agent_id] = q
        return q

    async def send(self, msg: Message) -> dict[str, Any]:
        await self._queues[msg.recipient].put(msg)
        return await msg.reply  # blocks until worker resolves


bus = A2AMessageBus()


class WorkerAgent:
    """Receives sub-tasks via the message bus and executes them."""

    def __init__(self, agent_id: str, client: PlatformClient) -> None:
        self.agent_id = agent_id
        self.client = client
        self.inbox = bus.register(agent_id)

    async def run(self) -> None:
        while True:
            msg = await self.inbox.get()
            result = await self._handle(msg)
            msg.reply.set_result(result)

    async def _handle(self, msg: Message) -> dict[str, Any]:
        task_id = msg.task_id
        topic = msg.payload.get("topic", "unknown")
        print(f"    [{self.agent_id}] handling task {task_id}: {topic}")

        # Simulate work + record a trace span
        await asyncio.sleep(0.1)
        answer = f"Analysis of '{topic}' complete (worker={self.agent_id})"

        self.client.trace(
            trace_id=msg.payload.get("trace_id", uuid.uuid4().hex),
            operation=f"worker.handle.{topic}",
            status="ok",
            duration_ms=100,
            metadata={"task_id": task_id},
        )

        # Store result as a memory entry so coordinator can retrieve it later
        self.client.store_memory(
            content=answer,
            memory_type="episodic",
            importance=0.6,
            tags=["a2a", "subtask", topic],
        )

        return {"task_id": task_id, "result": answer, "worker": self.agent_id}


class CoordinatorAgent:
    """Decomposes an objective, dispatches sub-tasks, aggregates results."""

    def __init__(self, agent_id: str, client: PlatformClient) -> None:
        self.agent_id = agent_id
        self.client = client

    async def run(self, objective: str, worker_ids: list[str]) -> str:
        trace_id = uuid.uuid4().hex
        print(f"\n[{self.agent_id}] objective: {objective}")
        print(f"[{self.agent_id}] trace_id:  {trace_id}")

        # Register an objective on the platform
        obj = self.client.run_objective(objective)
        objective_id = (obj or {}).get("objective_id")

        # Decompose into sub-topics (static for demo)
        topics = ["market overview", "technical landscape", "risk analysis"]

        # Dispatch one sub-task per worker in parallel
        async def dispatch(topic: str, worker_id: str) -> dict[str, Any]:
            task = self.client.create_task(
                title=topic,
                task_type="analysis",
                objective_id=objective_id,
            )
            task_id = (task or {}).get("task_id", uuid.uuid4().hex)
            msg = Message(
                sender=self.agent_id,
                recipient=worker_id,
                task_id=task_id,
                payload={"topic": topic, "objective_id": objective_id, "trace_id": trace_id},
                reply=asyncio.get_event_loop().create_future(),
            )
            result = await bus.send(msg)
            # Mark the platform task complete
            self.client.complete_task(task_id, result=result.get("result", ""))
            return result

        tasks = [dispatch(topic, wid) for topic, wid in zip(topics, worker_ids)]
        results = await asyncio.gather(*tasks)

        # Aggregate
        summary_lines = [r["result"] for r in results]
        final = f"Objective: {objective}\n" + "\n".join(f"  • {l}" for l in summary_lines)

        # Store final artifact
        self.client.create_artifact(
            title=f"A2A Report: {objective[:40]}",
            artifact_type="report",
            content=final,
            objective_id=objective_id,
        )

        self.client.trace(
            trace_id=trace_id,
            operation="coordinator.aggregate",
            status="ok",
            duration_ms=0,
            metadata={"workers": worker_ids, "subtask_count": len(topics)},
        )

        print(f"[{self.agent_id}] done.\n")
        print(final)
        return final


# ── Bootstrap ────────────────────────────────────────────────────────────────

async def main() -> None:
    coord_client = PlatformClient(tenant_id=TENANT, agent_id=COORD_ID)
    coord_client.register_agent(
        name="A2A Coordinator",
        description="Decomposes objectives and dispatches to workers",
        capabilities=CAPABILITIES,
        model="claude-sonnet-4-6",
        tags=["a2a", "coordinator"],
    )

    workers: list[WorkerAgent] = []
    for wid in WORKER_IDS:
        wc = PlatformClient(tenant_id=TENANT, agent_id=wid)
        wc.register_agent(
            name=f"A2A Worker {wid[-4:]}",
            description="Executes sub-tasks dispatched by coordinator",
            capabilities=CAPABILITIES,
            model="claude-sonnet-4-6",
            tags=["a2a", "worker"],
        )
        workers.append(WorkerAgent(wid, wc))

    # Start worker loops in background
    worker_tasks = [asyncio.create_task(w.run()) for w in workers]

    coordinator = CoordinatorAgent(COORD_ID, coord_client)
    await coordinator.run(
        objective="Analyse the impact of AI agents on enterprise workflows in 2025",
        worker_ids=WORKER_IDS,
    )

    # Cancel workers cleanly
    for t in worker_tasks:
        t.cancel()
    await asyncio.gather(*worker_tasks, return_exceptions=True)


if __name__ == "__main__":
    asyncio.run(main())
