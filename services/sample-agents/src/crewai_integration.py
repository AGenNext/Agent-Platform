"""
CrewAI integration with AGenNext Agent Platform.

Shows how to:
  1. Register each CrewAI agent role on the platform at startup
  2. Give agents platform-backed tools (memory search, knowledge retrieval)
  3. Hook task callbacks to store results as platform artifacts + traces
  4. Log token usage to billing after each crew run

Install extras:
    pip install crewai crewai-tools

Usage:
    ANTHROPIC_API_KEY=sk-ant-... python src/crewai_integration.py
"""

from __future__ import annotations

import os
import sys
import time
import uuid
from typing import Any

# ── Platform bootstrap ────────────────────────────────────────────────────────
PLATFORM_URL = os.getenv("PLATFORM_URL", "http://localhost:8001")
TENANT = os.getenv("PLATFORM_TENANT", "crewai-demo")

import httpx

_http = httpx.Client(base_url=PLATFORM_URL, timeout=20)

CAPABILITIES = [
    "reasoning", "memory", "tool_use", "code_execution",
    "web_search", "file_io", "multi_step", "self_evaluation",
]


def _post(path: str, body: dict) -> dict:
    try:
        r = _http.post(path, json=body)
        r.raise_for_status()
        return r.json()
    except Exception as e:
        print(f"  [platform] {path} → {e}")
        return {}


def _get(path: str, **params: Any) -> Any:
    try:
        r = _http.get(path, params=params)
        r.raise_for_status()
        return r.json()
    except Exception:
        return []


def register(agent_id: str, name: str, role: str) -> None:
    _post("/agents", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "name": name,
        "description": f"CrewAI role: {role}",
        "version": "1.0.0",
        "capabilities": CAPABILITIES,
        "model": "claude-sonnet-4-6",
        "tags": ["crewai", role.lower().replace(" ", "_")],
    })


def store_memory(agent_id: str, content: str, importance: float = 0.7, tags: list[str] | None = None) -> None:
    _post("/memory/store", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "content": content,
        "memory_type": "episodic",
        "importance": importance,
        "tags": tags or [],
    })


def search_memory(agent_id: str, query: str) -> list[dict]:
    try:
        r = _http.get(f"/memory/{agent_id}/search", params={"q": query, "limit": 5})
        r.raise_for_status()
        return r.json()
    except Exception:
        return []


def create_artifact(agent_id: str, objective_id: str | None, title: str, content: str) -> str:
    resp = _post("/artifacts", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "objective_id": objective_id,
        "title": title,
        "artifact_type": "report",
        "content": content,
        "format": "markdown",
    })
    return resp.get("artifact_id", "")


def record_trace(trace_id: str, agent_id: str, operation: str, duration_ms: int = 0, meta: dict | None = None) -> None:
    _post("/traces", {
        "trace_id": trace_id,
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "span_id": uuid.uuid4().hex[:16],
        "operation": operation,
        "status": "ok",
        "duration_ms": duration_ms,
        "metadata": meta or {},
    })


def log_usage(agent_id: str, model: str, input_tokens: int, output_tokens: int) -> None:
    cost = (input_tokens * 3 + output_tokens * 15) / 1_000_000  # claude-sonnet-4-6 pricing
    _post("/billing/usage", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "model": model,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cost_usd": cost,
    })


# ── CrewAI import guard ───────────────────────────────────────────────────────
try:
    from crewai import Agent, Crew, Process, Task
    from crewai.tools import BaseTool
    from pydantic import BaseModel, Field
    CREWAI_AVAILABLE = True
except ImportError:
    CREWAI_AVAILABLE = False
    print("crewai not installed — running in stub mode (pip install crewai)")


# ── Platform-backed tools ─────────────────────────────────────────────────────

if CREWAI_AVAILABLE:
    class MemorySearchInput(BaseModel):
        query: str = Field(description="Search query for the agent memory store")
        agent_id: str = Field(description="Agent whose memory to search")

    class MemorySearchTool(BaseTool):
        name: str = "platform_memory_search"
        description: str = (
            "Search the AGenNext platform memory store for relevant past findings. "
            "Use this before starting research to avoid duplicating previous work."
        )
        args_schema: type[BaseModel] = MemorySearchInput

        def _run(self, query: str, agent_id: str) -> str:
            results = search_memory(agent_id, query)
            if not results:
                return "No relevant memories found."
            lines = [f"- {r.get('content', '')}" for r in results[:5]]
            return "Past findings:\n" + "\n".join(lines)

    class KnowledgeSearchInput(BaseModel):
        query: str = Field(description="Search query for the knowledge base")

    class KnowledgeSearchTool(BaseTool):
        name: str = "platform_knowledge_search"
        description: str = (
            "Search the AGenNext platform knowledge base (BM25 full-text search). "
            "Returns relevant document chunks with relevance scores."
        )
        args_schema: type[BaseModel] = KnowledgeSearchInput

        def _run(self, query: str) -> str:
            results = _get("/knowledge/search", q=query, tenant_id=TENANT, limit=5)
            if not results:
                return "No knowledge base results."
            lines = [f"[{r.get('score', 0):.2f}] {r.get('content', '')[:200]}" for r in results]
            return "Knowledge base results:\n" + "\n".join(lines)


# ── CrewAI task callback ──────────────────────────────────────────────────────

def make_task_callback(agent_id: str, trace_id: str):
    """Returns a CrewAI task callback that instruments every task completion."""
    def callback(output: Any) -> None:
        content = str(output.raw) if hasattr(output, "raw") else str(output)
        store_memory(agent_id, content[:1000], importance=0.75, tags=["crewai", "task_output"])
        record_trace(trace_id, agent_id, "crewai.task.complete", meta={"output_chars": len(content)})
        # Log synthetic usage (CrewAI doesn't expose token counts directly without LLM callback)
        log_usage(agent_id, "claude-sonnet-4-6", input_tokens=500, output_tokens=len(content) // 4)
    return callback


# ── Crew definition ───────────────────────────────────────────────────────────

RESEARCHER_ID = f"crew-researcher-{uuid.uuid4().hex[:6]}"
ANALYST_ID = f"crew-analyst-{uuid.uuid4().hex[:6]}"
WRITER_ID = f"crew-writer-{uuid.uuid4().hex[:6]}"
TRACE_ID = uuid.uuid4().hex
OBJECTIVE_ID: str | None = None


def run_crew(topic: str) -> str:
    global OBJECTIVE_ID

    print(f"\n[CrewAI → Platform] topic: {topic}")
    print(f"[CrewAI → Platform] trace:  {TRACE_ID}\n")

    # Register agents on the platform
    register(RESEARCHER_ID, "CrewAI Researcher", "researcher")
    register(ANALYST_ID, "CrewAI Analyst", "analyst")
    register(WRITER_ID, "CrewAI Writer", "writer")

    # Create objective
    obj = _post("/objectives", {
        "tenant_id": TENANT,
        "agent_id": RESEARCHER_ID,
        "title": f"CrewAI: {topic[:60]}",
        "description": topic,
        "priority": "high",
    })
    OBJECTIVE_ID = obj.get("objective_id")

    if not CREWAI_AVAILABLE:
        return _stub_run(topic)

    model = os.getenv("CREWAI_MODEL", "claude-3-5-sonnet-20241022")
    mem_tool = MemorySearchTool()
    kb_tool = KnowledgeSearchTool()

    researcher = Agent(
        role="Senior Research Analyst",
        goal=f"Gather comprehensive, factual information about: {topic}",
        backstory=(
            "You are an expert researcher who finds accurate, up-to-date information. "
            "Always search platform memory first before conducting new research."
        ),
        tools=[mem_tool, kb_tool],
        llm=model,
        verbose=True,
    )

    analyst = Agent(
        role="Strategic Analyst",
        goal="Identify key insights, trends, and implications from research findings",
        backstory=(
            "You excel at synthesising large amounts of information into clear, "
            "actionable insights. You never speculate without evidence."
        ),
        tools=[mem_tool],
        llm=model,
        verbose=True,
    )

    writer = Agent(
        role="Technical Writer",
        goal="Produce a clear, structured report suitable for executive review",
        backstory=(
            "You transform complex analyses into compelling narratives. "
            "Your reports are concise, well-structured, and evidence-based."
        ),
        llm=model,
        verbose=True,
    )

    research_task = Task(
        description=f"Research the following topic thoroughly: {topic}. "
                    f"Search platform memory first, then gather new information.",
        expected_output="Detailed research findings with sources and key data points",
        agent=researcher,
        callback=make_task_callback(RESEARCHER_ID, TRACE_ID),
    )

    analysis_task = Task(
        description="Analyse the research findings. Identify the top 5 insights, "
                    "key risks, and strategic opportunities.",
        expected_output="Structured analysis with insights, risks, and opportunities",
        agent=analyst,
        context=[research_task],
        callback=make_task_callback(ANALYST_ID, TRACE_ID),
    )

    writing_task = Task(
        description="Write a professional executive report based on the research and analysis. "
                    "Use markdown with clear sections: Executive Summary, Key Findings, "
                    "Analysis, Recommendations, Conclusion.",
        expected_output="Complete markdown report ready for executive review",
        agent=writer,
        context=[research_task, analysis_task],
        callback=make_task_callback(WRITER_ID, TRACE_ID),
    )

    crew = Crew(
        agents=[researcher, analyst, writer],
        tasks=[research_task, analysis_task, writing_task],
        process=Process.sequential,
        verbose=True,
    )

    t0 = time.time()
    result = crew.kickoff()
    elapsed_ms = int((time.time() - t0) * 1000)

    report = str(result.raw) if hasattr(result, "raw") else str(result)

    # Store final artifact on platform
    art_id = create_artifact(WRITER_ID, OBJECTIVE_ID, f"CrewAI Report: {topic[:50]}", report)
    record_trace(TRACE_ID, WRITER_ID, "crewai.crew.complete",
                 duration_ms=elapsed_ms, meta={"artifact_id": art_id, "topic": topic})

    print(f"\n[Platform] artifact stored: {art_id}")
    print(f"[Platform] trace:           {TRACE_ID}")
    return report


def _stub_run(topic: str) -> str:
    """Runs without crewai installed — demonstrates platform wiring only."""
    print("[stub] CrewAI not installed; showing platform wiring only.\n")

    for agent_id, role, content in [
        (RESEARCHER_ID, "research", f"Research findings on '{topic}': comprehensive data gathered."),
        (ANALYST_ID, "analysis", f"Analysis of '{topic}': 5 key insights identified."),
        (WRITER_ID, "writing", f"# Report: {topic}\n\nExecutive summary and recommendations."),
    ]:
        store_memory(agent_id, content, importance=0.7, tags=["crewai", role])
        record_trace(TRACE_ID, agent_id, f"crewai.{role}.complete", duration_ms=100)
        log_usage(agent_id, "claude-sonnet-4-6", 400, 200)
        print(f"  [stub] {role} complete → memory + trace recorded")

    report = f"# CrewAI Stub Report: {topic}\n\nPlatform wiring verified. Install crewai to run real agents."
    art_id = create_artifact(WRITER_ID, OBJECTIVE_ID, f"CrewAI Stub: {topic[:50]}", report)
    record_trace(TRACE_ID, WRITER_ID, "crewai.crew.complete", meta={"artifact_id": art_id})
    print(f"\n[Platform] artifact: {art_id}  trace: {TRACE_ID}")
    return report


if __name__ == "__main__":
    topic = " ".join(sys.argv[1:]) or "The impact of AI agents on enterprise software development"
    report = run_crew(topic)
    print("\n" + "═" * 60)
    print(report[:2000])
