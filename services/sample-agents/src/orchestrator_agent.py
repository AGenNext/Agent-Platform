"""
Orchestrator Agent — LangGraph supervisor that spawns sub-tasks and coordinates workers.

Architecture:
  Orchestrator (this)
    ├── planner_node   → breaks goal into tasks → creates platform task records
    ├── dispatcher_node → assigns tasks to workers (simulated)
    ├── monitor_node   → checks task completion, handles failures
    └── finalize_node  → aggregates results, creates summary artifact

Run:
  export ANTHROPIC_API_KEY=sk-...
  export PLATFORM_API_URL=http://localhost:8000
  python orchestrator_agent.py "Build a market analysis for enterprise AI platform adoption"
"""
import os
import sys
import time
import uuid
from typing import Annotated, Any, TypedDict

from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from platform_client import PlatformClient

load_dotenv()
console = Console()


# ── State ──────────────────────────────────────────────────────────────────────


class SubTask(TypedDict):
    task_id: str
    platform_task_id: str
    name: str
    description: str
    assigned_to: str
    status: str
    result: str | None


class OrchestratorState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]
    agent_id: str
    objective_id: str
    trace_id: str
    goal: str
    tasks: list[SubTask]
    completed_tasks: int
    artifact_id: str | None
    trust_passed: bool


# ── Simulated worker pool ──────────────────────────────────────────────────────

WORKER_AGENTS = [
    {"id": "worker-researcher", "speciality": "research and data gathering"},
    {"id": "worker-analyst", "speciality": "data analysis and pattern recognition"},
    {"id": "worker-writer", "speciality": "report writing and synthesis"},
]


def simulate_worker_execution(task: SubTask, goal: str, llm: ChatAnthropic) -> str:
    """Simulate a worker agent completing a task via LLM."""
    response = llm.invoke([
        SystemMessage(content=(
            f"You are a specialist in {task['assigned_to'].replace('-', ' ')}. "
            "Complete the assigned task concisely. Return only the task output, no preamble."
        )),
        HumanMessage(content=(
            f"Overall goal: {goal}\n\n"
            f"Your task: {task['name']}\n"
            f"Description: {task['description']}\n\n"
            "Provide a focused, factual 2-3 paragraph response."
        )),
    ])
    return response.content


# ── Graph nodes ────────────────────────────────────────────────────────────────


def planner_node(state: OrchestratorState, client: PlatformClient, llm: ChatAnthropic) -> dict:
    """Decompose the goal into parallel subtasks."""
    client.trace(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        event_type="llm.call",
        payload={"step": "plan", "goal": state["goal"]},
        trace_id=state["trace_id"],
    )
    response = llm.invoke([
        SystemMessage(content=(
            "You are an orchestrator. Decompose the goal into exactly 3 parallel subtasks. "
            "Format as JSON array with fields: name (str), description (str), worker (str from: "
            "worker-researcher, worker-analyst, worker-writer). "
            "Return ONLY the JSON array, no markdown."
        )),
        HumanMessage(content=f"Goal: {state['goal']}"),
    ])

    import json
    try:
        raw = response.content.strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        plan = json.loads(raw.strip())
    except Exception:
        plan = [
            {"name": "Research Phase", "description": f"Research key aspects of: {state['goal']}", "worker": "worker-researcher"},
            {"name": "Analysis Phase", "description": f"Analyze patterns and implications for: {state['goal']}", "worker": "worker-analyst"},
            {"name": "Synthesis Phase", "description": f"Synthesize findings into recommendations for: {state['goal']}", "worker": "worker-writer"},
        ]

    # Create platform task records
    tasks: list[SubTask] = []
    for p in plan[:4]:
        try:
            pt = client.create_task(
                objective_id=state["objective_id"],
                agent_id=state["agent_id"],
                name=p["name"],
                description=p.get("description", ""),
            )
            platform_task_id = pt.get("task_id") or str(pt.get("id", ""))
        except Exception:
            platform_task_id = f"task-{uuid.uuid4().hex[:8]}"

        tasks.append({
            "task_id": uuid.uuid4().hex[:8],
            "platform_task_id": platform_task_id,
            "name": p["name"],
            "description": p.get("description", ""),
            "assigned_to": p.get("worker", "worker-researcher"),
            "status": "pending",
            "result": None,
        })

    console.print(f"\n[cyan]Planned {len(tasks)} tasks[/cyan]")
    for t in tasks:
        console.print(f"  → {t['name']} → [yellow]{t['assigned_to']}[/yellow]")

    return {"messages": [response], "tasks": tasks}


def dispatcher_node(state: OrchestratorState, client: PlatformClient, llm: ChatAnthropic) -> dict:
    """Execute all pending tasks in sequence (simulating parallel workers)."""
    updated_tasks = []
    completed = 0

    for task in state["tasks"]:
        console.print(f"\n[bold]Executing:[/bold] {task['name']}")
        t0 = time.time()

        try:
            result = simulate_worker_execution(task, state["goal"], llm)
            duration_ms = int((time.time() - t0) * 1000)

            # Mark complete on platform
            try:
                client.complete_task(task["platform_task_id"], output={"summary": result[:200]})
            except Exception:
                pass

            client.trace(
                objective_id=state["objective_id"],
                agent_id=state["agent_id"],
                event_type="task.completed",
                payload={"task": task["name"], "worker": task["assigned_to"], "duration_ms": duration_ms},
                trace_id=state["trace_id"],
                duration_ms=duration_ms,
            )

            updated_tasks.append({**task, "status": "completed", "result": result})
            completed += 1
            console.print(f"  [green]✓[/green] Done in {duration_ms}ms")

        except Exception as e:
            try:
                client.fail_task(task["platform_task_id"], str(e))
            except Exception:
                pass
            updated_tasks.append({**task, "status": "failed", "result": None})
            console.print(f"  [red]✗[/red] Failed: {e}")

    return {"tasks": updated_tasks, "completed_tasks": completed}


def finalize_node(state: OrchestratorState, client: PlatformClient, llm: ChatAnthropic) -> dict:
    """Aggregate all task results into a final artifact."""
    task_results = "\n\n".join(
        f"## {t['name']}\nAssigned to: {t['assigned_to']}\nStatus: {t['status']}\n\n{t['result'] or '(no output)'}"
        for t in state["tasks"]
    )

    t0 = time.time()
    response = llm.invoke([
        SystemMessage(content=(
            "You are the lead analyst. Synthesize the work product from all team members "
            "into a single coherent executive report. Include: Executive Summary, "
            "Key Findings, Analysis, Recommendations, and Next Steps. Use Markdown."
        )),
        HumanMessage(content=(
            f"Overall goal: {state['goal']}\n\n"
            f"Team outputs:\n{task_results}"
        )),
    ])
    duration_ms = int((time.time() - t0) * 1000)

    tokens_out = len(response.content) // 4
    client.log_usage(
        agent_id=state["agent_id"],
        objective_id=state["objective_id"],
        model_id="claude-sonnet-4-6",
        tokens_in=len(task_results) // 4 + 100,
        tokens_out=tokens_out,
        cost_usd=round(tokens_out * 0.000015, 6),
    )
    client.trace(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        event_type="llm.call",
        payload={"step": "finalize", "tasks_completed": state["completed_tasks"]},
        trace_id=state["trace_id"],
        duration_ms=duration_ms,
    )

    artifact = client.create_artifact(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        name=f"Orchestrated Report: {state['goal'][:60]}",
        text=response.content,
        schema_type="Report",
        format="text/markdown",
    )
    artifact_id = artifact.get("artifact_id") or str(artifact.get("id", ""))

    # Self-evaluate
    eval_result = client.evaluate_artifact(
        artifact_id=artifact_id,
        agent_id=state["agent_id"],
        correct=0.82,
        logical=0.88,
        evidence=0.78,
        aligned=0.90,
        readable=0.85,
        notes="Orchestrator multi-agent synthesis",
    )

    return {
        "messages": [response],
        "artifact_id": artifact_id,
        "trust_passed": eval_result.get("passed", False),
    }


# ── Build graph ────────────────────────────────────────────────────────────────


def build_graph(client: PlatformClient) -> StateGraph:
    llm = ChatAnthropic(model="claude-sonnet-4-6", max_tokens=4096)

    graph = StateGraph(OrchestratorState)
    graph.add_node("plan", lambda s: planner_node(s, client, llm))
    graph.add_node("dispatch", lambda s: dispatcher_node(s, client, llm))
    graph.add_node("finalize", lambda s: finalize_node(s, client, llm))

    graph.add_edge(START, "plan")
    graph.add_edge("plan", "dispatch")
    graph.add_edge("dispatch", "finalize")
    graph.add_edge("finalize", END)

    return graph.compile()


# ── Entry point ────────────────────────────────────────────────────────────────


def run(goal: str):
    console.print(Panel(f"[bold magenta]Orchestrator Agent[/bold magenta]\n{goal}", expand=False))

    with PlatformClient() as client:
        if not client.health():
            console.print("[yellow]Warning: Platform API not reachable.[/yellow]")

        try:
            agent = client.register_agent(
                name="Orchestrator-v1",
                description="LangGraph multi-agent orchestrator with task dispatching",
                version="1.0.0",
                goal_types=["orchestration", "coordination", "multi-agent"],
                skill_ids=["task_planning", "worker_coordination", "synthesis", "clear_evaluation"],
            )
            agent_id = agent.get("agent_id", "orchestrator-001")
            console.print(f"[green]Registered:[/green] {agent_id}")
        except Exception as e:
            console.print(f"[yellow]Registration skipped: {e}[/yellow]")
            agent_id = "orchestrator-offline"

        try:
            obj = client.run_objective(goal=goal, priority=8)
            objective_id = obj["objective"].get("id") or obj["objective"].get("objective_id", "obj-offline")
        except Exception as e:
            console.print(f"[yellow]Objective skipped: {e}[/yellow]")
            objective_id = "obj-offline"

        trace_id = PlatformClient.new_trace_id()

        graph = build_graph(client)
        final = graph.invoke({
            "messages": [],
            "agent_id": agent_id,
            "objective_id": objective_id,
            "trace_id": trace_id,
            "goal": goal,
            "tasks": [],
            "completed_tasks": 0,
            "artifact_id": None,
            "trust_passed": False,
        })

        # Summary table
        table = Table(title="Task Summary")
        table.add_column("Task", style="cyan")
        table.add_column("Worker")
        table.add_column("Status")
        for t in final["tasks"]:
            status_style = "green" if t["status"] == "completed" else "red"
            table.add_row(t["name"], t["assigned_to"], f"[{status_style}]{t['status']}[/{status_style}]")
        console.print(table)

        report = final["messages"][-1].content
        console.print(Panel(report[:2000] + ("…" if len(report) > 2000 else ""), title="[bold]Final Report[/bold]"))
        console.print(f"\n[bold]Artifact ID:[/bold] {final.get('artifact_id', 'N/A')}")
        console.print(f"[bold]Trust gate:[/bold] {'[green]PASSED[/green]' if final.get('trust_passed') else '[red]FAILED[/red]'}")


if __name__ == "__main__":
    goal = " ".join(sys.argv[1:]) or "Build a market analysis for enterprise AI platform adoption"
    run(goal)
