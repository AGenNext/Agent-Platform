"""
Researcher Agent — LangGraph ReAct loop wired to the AGenNext platform.

Flow:
  1. Register with the platform (once)
  2. Receive a research goal
  3. Plan → search → synthesize → write artifact
  4. Store key findings in episodic memory
  5. Self-evaluate the artifact via CLEAR dimensions
  6. Log traces and usage throughout

Run:
  export ANTHROPIC_API_KEY=sk-...
  export PLATFORM_API_URL=http://localhost:8000
  python researcher_agent.py "What are the main use cases for SurrealDB in AI systems?"
"""
import os
import sys
import time
from typing import Annotated, TypedDict

from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from rich.console import Console
from rich.panel import Panel

from platform_client import PlatformClient

load_dotenv()
console = Console()

# ── Tools ─────────────────────────────────────────────────────────────────────


@tool
def web_search(query: str) -> str:
    """Search for information. Returns a summary of findings for the query."""
    # In production, wire to Tavily, Brave, or SerpAPI.
    # This stub returns structured placeholder results for demonstration.
    return (
        f"[Search results for: {query}]\n\n"
        "1. SurrealDB is a multi-model database supporting relational, graph, and document data in one system.\n"
        "2. Key AI use cases: vector similarity search (MTREE), BM25 full-text search, real-time LIVE SELECT subscriptions.\n"
        "3. DEFINE EVENT enables reactive data pipelines — analytics, memory seeding, notifications without ETL.\n"
        "4. Schema.org JSON-LD graph model lets every entity be graph-queryable without separate tooling.\n"
        "5. DEFINE FUNCTION moves business logic into the DB — no round-trips for trust scoring or billing.\n"
    )


@tool
def read_memory(query: str, agent_id: str) -> str:
    """Recall relevant memories for a query."""
    try:
        client = PlatformClient()
        results = client.search_memory(agent_id=agent_id, query=query, limit=3)
        if not results:
            return "No relevant memories found."
        return "\n".join(f"- {m['content']}" for m in results)
    except Exception as e:
        return f"Memory search error: {e}"


# ── State ──────────────────────────────────────────────────────────────────────


class ResearchState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]
    agent_id: str
    objective_id: str
    trace_id: str
    goal: str
    artifact_id: str | None
    trust_passed: bool


# ── Graph nodes ────────────────────────────────────────────────────────────────


def plan_node(state: ResearchState, client: PlatformClient, llm: ChatAnthropic) -> dict:
    """Create a research plan for the goal."""
    client.trace(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        event_type="llm.call",
        payload={"step": "plan", "goal": state["goal"]},
        trace_id=state["trace_id"],
    )
    response = llm.invoke([
        SystemMessage(content=(
            "You are a research planner. Given a research goal, produce a numbered list "
            "of 3-5 specific search queries to answer it thoroughly."
        )),
        HumanMessage(content=f"Research goal: {state['goal']}"),
    ])
    return {"messages": [response]}


def research_node(state: ResearchState, client: PlatformClient, llm_with_tools) -> dict:
    """Execute the research plan using available tools."""
    client.trace(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        event_type="tool.call",
        payload={"step": "research"},
        trace_id=state["trace_id"],
    )
    system = SystemMessage(content=(
        "You are a researcher. Use the web_search tool to gather information. "
        "Run multiple searches to cover the topic thoroughly. "
        "Also use read_memory to recall any relevant context you may already know."
    ))
    messages = [system] + state["messages"]
    response = llm_with_tools.invoke(messages)
    return {"messages": [response]}


def tool_node(state: ResearchState, tools_map: dict) -> dict:
    """Execute tool calls from the last AI message."""
    last = state["messages"][-1]
    results = []
    for tc in getattr(last, "tool_calls", []):
        fn = tools_map.get(tc["name"])
        args = tc["args"]
        # Inject agent_id for memory tool
        if tc["name"] == "read_memory":
            args = {**args, "agent_id": state["agent_id"]}
        try:
            output = fn.invoke(args) if fn else f"Unknown tool: {tc['name']}"
        except Exception as e:
            output = f"Tool error: {e}"
        results.append(ToolMessage(content=str(output), tool_call_id=tc["id"]))
    return {"messages": results}


def synthesize_node(state: ResearchState, client: PlatformClient, llm: ChatAnthropic) -> dict:
    """Synthesize research into a final artifact."""
    t0 = time.time()
    response = llm.invoke([
        SystemMessage(content=(
            "You are a technical writer. Based on the research gathered, write a clear, "
            "well-structured report in Markdown. Include: Executive Summary, Key Findings "
            "(with evidence), Implications, and Conclusion. Be factual and cite your sources."
        )),
        *state["messages"],
        HumanMessage(content=f"Write the final report for: {state['goal']}"),
    ])
    duration_ms = int((time.time() - t0) * 1000)

    # Estimate tokens (rough: 4 chars ≈ 1 token)
    tokens_out = len(response.content) // 4
    tokens_in = sum(len(str(m.content)) // 4 for m in state["messages"]) + 50

    client.log_usage(
        agent_id=state["agent_id"],
        objective_id=state["objective_id"],
        model_id="claude-sonnet-4-6",
        tokens_in=tokens_in,
        tokens_out=tokens_out,
        cost_usd=round((tokens_in * 0.000003) + (tokens_out * 0.000015), 6),
    )
    client.trace(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        event_type="llm.call",
        payload={"step": "synthesize", "tokens_out": tokens_out},
        trace_id=state["trace_id"],
        duration_ms=duration_ms,
    )
    return {"messages": [response]}


def write_artifact_node(state: ResearchState, client: PlatformClient) -> dict:
    """Write the final report as a platform artifact."""
    report = state["messages"][-1].content
    artifact = client.create_artifact(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        name=f"Research: {state['goal'][:60]}",
        text=report,
        schema_type="Report",
        format="text/markdown",
    )
    artifact_id = artifact.get("artifact_id") or str(artifact.get("id", ""))
    client.trace(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        event_type="artifact.created",
        payload={"artifact_id": artifact_id, "length": len(report)},
        trace_id=state["trace_id"],
    )
    return {"artifact_id": artifact_id}


def store_memory_node(state: ResearchState, client: PlatformClient, llm: ChatAnthropic) -> dict:
    """Extract and store key findings as episodic memories."""
    report = state["messages"][-1].content
    response = llm.invoke([
        SystemMessage(content=(
            "Extract 3-5 key facts from this report as concise bullet points. "
            "Each bullet should be a standalone, memorable insight."
        )),
        HumanMessage(content=report),
    ])
    facts = [f.strip().lstrip("•-").strip() for f in response.content.split("\n") if f.strip().startswith(("-", "•", "*"))]
    for i, fact in enumerate(facts[:5]):
        client.store_memory(
            agent_id=state["agent_id"],
            content=fact,
            memory_type="semantic",
            importance=0.7 + (i == 0) * 0.2,
            tags=["research", "auto-extracted"],
        )
    return {}


def evaluate_node(state: ResearchState, client: PlatformClient, llm: ChatAnthropic) -> dict:
    """Self-evaluate the artifact using CLEAR dimensions."""
    if not state.get("artifact_id"):
        return {"trust_passed": False}

    report = state["messages"][-1].content
    response = llm.invoke([
        SystemMessage(content=(
            "Evaluate this research report on 5 CLEAR dimensions, each scored 0.0-1.0:\n"
            "- correct: factual accuracy and absence of errors\n"
            "- logical: coherent reasoning and structure\n"
            "- evidence: claims backed by sources\n"
            "- aligned: stays on topic and meets the goal\n"
            "- readable: clear prose, good formatting\n\n"
            "Respond with EXACTLY this format (numbers only, no text):\n"
            "correct: 0.X\nlogical: 0.X\nevidence: 0.X\naligned: 0.X\nreadable: 0.X"
        )),
        HumanMessage(content=f"Goal: {state['goal']}\n\nReport:\n{report[:3000]}"),
    ])

    scores = {"correct": 0.8, "logical": 0.8, "evidence": 0.75, "aligned": 0.85, "readable": 0.8}
    for line in response.content.strip().split("\n"):
        if ":" in line:
            key, _, val = line.partition(":")
            key = key.strip().lower()
            if key in scores:
                try:
                    scores[key] = float(val.strip())
                except ValueError:
                    pass

    result = client.evaluate_artifact(
        artifact_id=state["artifact_id"],
        agent_id=state["agent_id"],
        notes="Researcher self-evaluation",
        **scores,
    )
    passed = result.get("passed", False)
    client.trace(
        objective_id=state["objective_id"],
        agent_id=state["agent_id"],
        event_type="trust.evaluated",
        payload={"scores": scores, "passed": passed, "composite": result.get("composite_score")},
        trace_id=state["trace_id"],
    )
    return {"trust_passed": passed}


# ── Router ─────────────────────────────────────────────────────────────────────


def should_continue(state: ResearchState) -> str:
    """Route after research: keep using tools or move to synthesize."""
    last = state["messages"][-1]
    if isinstance(last, AIMessage) and getattr(last, "tool_calls", None):
        return "tools"
    return "synthesize"


# ── Build graph ────────────────────────────────────────────────────────────────


def build_graph(client: PlatformClient) -> StateGraph:
    llm = ChatAnthropic(model="claude-sonnet-4-6", max_tokens=4096)
    tools = [web_search, read_memory]
    tools_map = {t.name: t for t in tools}
    llm_with_tools = llm.bind_tools(tools)

    graph = StateGraph(ResearchState)
    graph.add_node("plan", lambda s: plan_node(s, client, llm))
    graph.add_node("research", lambda s: research_node(s, client, llm_with_tools))
    graph.add_node("tools", lambda s: tool_node(s, tools_map))
    graph.add_node("synthesize", lambda s: synthesize_node(s, client, llm))
    graph.add_node("write_artifact", lambda s: write_artifact_node(s, client))
    graph.add_node("store_memory", lambda s: store_memory_node(s, client, llm))
    graph.add_node("evaluate", lambda s: evaluate_node(s, client, llm))

    graph.add_edge(START, "plan")
    graph.add_edge("plan", "research")
    graph.add_conditional_edges("research", should_continue, {"tools": "tools", "synthesize": "synthesize"})
    graph.add_edge("tools", "research")
    graph.add_edge("synthesize", "write_artifact")
    graph.add_edge("write_artifact", "store_memory")
    graph.add_edge("store_memory", "evaluate")
    graph.add_edge("evaluate", END)

    return graph.compile()


# ── Entry point ────────────────────────────────────────────────────────────────


def run(goal: str):
    console.print(Panel(f"[bold cyan]Researcher Agent[/bold cyan]\n{goal}", expand=False))

    with PlatformClient() as client:
        # Health check
        if not client.health():
            console.print("[yellow]Warning: Platform API not reachable. Running in offline mode.[/yellow]")

        # Register agent
        try:
            agent = client.register_agent(
                name="Researcher-v1",
                description="LangGraph ReAct researcher with CLEAR self-evaluation",
                version="1.0.0",
                goal_types=["research", "analysis", "summarization"],
                skill_ids=["web_search", "memory_retrieval", "synthesis", "clear_evaluation"],
            )
            agent_id = agent.get("agent_id", "researcher-001")
            console.print(f"[green]Registered:[/green] {agent_id}")
        except Exception as e:
            console.print(f"[yellow]Registration skipped: {e}[/yellow]")
            agent_id = "researcher-offline"

        # Create objective
        try:
            obj = client.run_objective(goal=goal, priority=7)
            objective_id = obj["objective"].get("id") or obj["objective"].get("objective_id", "obj-offline")
            console.print(f"[green]Objective:[/green] {objective_id}")
        except Exception as e:
            console.print(f"[yellow]Objective skipped: {e}[/yellow]")
            objective_id = "obj-offline"

        trace_id = PlatformClient.new_trace_id()

        # Run graph
        graph = build_graph(client)
        final = graph.invoke({
            "messages": [],
            "agent_id": agent_id,
            "objective_id": objective_id,
            "trace_id": trace_id,
            "goal": goal,
            "artifact_id": None,
            "trust_passed": False,
        })

        # Print result
        report = final["messages"][-1].content
        console.print(Panel(report[:2000] + ("…" if len(report) > 2000 else ""), title="[bold]Report[/bold]"))
        console.print(f"\n[bold]Artifact ID:[/bold] {final.get('artifact_id', 'N/A')}")
        console.print(f"[bold]Trust gate:[/bold] {'[green]PASSED[/green]' if final.get('trust_passed') else '[red]FAILED[/red]'}")


if __name__ == "__main__":
    goal = " ".join(sys.argv[1:]) or "What are the main use cases for SurrealDB in AI agent systems?"
    run(goal)
