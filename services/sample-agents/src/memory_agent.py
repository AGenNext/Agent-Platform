"""
Memory Agent — LangChain agent with persistent episodic + semantic memory via the platform API.

Demonstrates:
  - Storing observations as episodic memories after each turn
  - Recalling relevant context via BM25 search before each response
  - Upgrading episodic → semantic memories after repeated access
  - Working memory for in-flight reasoning (cleared each session)

Run:
  export ANTHROPIC_API_KEY=sk-...
  export PLATFORM_API_URL=http://localhost:8000
  python memory_agent.py
"""
import os
import sys
from typing import Any

from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt

from platform_client import PlatformClient

load_dotenv()
console = Console()


class MemoryAgent:
    """
    Conversational agent that maintains persistent memory via the platform API.

    Memory tiers:
      - working    : current session context (in-process list, cleared on restart)
      - episodic   : recent observations (stored after each turn, importance 0.4-0.6)
      - semantic   : distilled facts (importance 0.7-1.0, survives sessions)
    """

    def __init__(self, client: PlatformClient, agent_id: str, objective_id: str):
        self.client = client
        self.agent_id = agent_id
        self.objective_id = objective_id
        self.trace_id = PlatformClient.new_trace_id()
        self.llm = ChatAnthropic(model="claude-sonnet-4-6", max_tokens=2048)
        self.working_memory: list[dict] = []
        self.turn = 0

    def recall(self, query: str, limit: int = 4) -> list[dict]:
        """Search episodic + semantic memory for relevant context."""
        try:
            return self.client.search_memory(self.agent_id, query, limit=limit)
        except Exception:
            return []

    def remember(self, content: str, memory_type: str = "episodic", importance: float = 0.5, tags: list[str] | None = None):
        """Store a new memory."""
        try:
            self.client.store_memory(
                agent_id=self.agent_id,
                content=content,
                memory_type=memory_type,
                importance=importance,
                tags=tags or [],
            )
        except Exception:
            pass

    def respond(self, user_message: str) -> str:
        self.turn += 1

        # 1. Recall relevant memories
        memories = self.recall(user_message)
        memory_context = ""
        if memories:
            memory_context = "\n\nRelevant memories:\n" + "\n".join(
                f"  [{m.get('memory_type', '?')}|imp:{m.get('importance', 0):.1f}] {m['content']}"
                for m in memories
            )

        # 2. Build working context (last 6 turns)
        recent = self.working_memory[-6:]
        history: list[BaseMessage] = []
        for turn in recent:
            history.append(HumanMessage(content=turn["user"]))
            history.append(AIMessage(content=turn["assistant"]))

        # 3. Call LLM
        self.client.trace(
            objective_id=self.objective_id,
            agent_id=self.agent_id,
            event_type="llm.call",
            payload={"turn": self.turn, "memories_recalled": len(memories)},
            trace_id=self.trace_id,
        )
        system = SystemMessage(content=(
            "You are a helpful AI assistant with persistent memory. "
            "You remember past conversations and build on them over time. "
            "Be concise but warm. Reference relevant memories when they add value."
            + memory_context
        ))
        response = self.llm.invoke([system] + history + [HumanMessage(content=user_message)])
        answer = response.content

        # 4. Store this turn as episodic memory
        self.remember(
            content=f"User asked: {user_message[:150]} → I responded: {answer[:150]}",
            memory_type="episodic",
            importance=0.45,
            tags=["conversation", f"turn-{self.turn}"],
        )

        # 5. If turn is a notable fact, upgrade to semantic
        if any(kw in user_message.lower() for kw in ["my name is", "i work at", "i prefer", "remember that", "important:"]):
            self.remember(
                content=f"User shared: {user_message}",
                memory_type="semantic",
                importance=0.85,
                tags=["user-preference", "semantic"],
            )

        # 6. Add to working memory
        self.working_memory.append({"user": user_message, "assistant": answer})

        # 7. Log usage
        self.client.log_usage(
            agent_id=self.agent_id,
            objective_id=self.objective_id,
            model_id="claude-sonnet-4-6",
            tokens_in=len(user_message) // 4 + len(memory_context) // 4,
            tokens_out=len(answer) // 4,
            cost_usd=round(len(answer) // 4 * 0.000015, 6),
        )

        return answer


def run():
    console.print(Panel("[bold blue]Memory Agent[/bold blue]\nPersistent memory via AGenNext platform\nType 'quit' to exit", expand=False))

    with PlatformClient() as client:
        if not client.health():
            console.print("[yellow]Warning: Platform API not reachable. Running in offline mode.[/yellow]")

        # Register
        try:
            agent = client.register_agent(
                name="MemoryAgent-v1",
                description="Conversational agent with episodic and semantic memory",
                version="1.0.0",
                goal_types=["conversation", "assistance", "memory"],
                skill_ids=["memory_retrieval", "memory_storage", "conversation"],
            )
            agent_id = agent.get("agent_id", "memory-agent-001")
            console.print(f"[green]Registered:[/green] {agent_id}\n")
        except Exception as e:
            console.print(f"[yellow]Registration skipped: {e}[/yellow]")
            agent_id = "memory-offline"

        try:
            obj = client.run_objective(goal="Persistent memory conversation session", priority=3)
            objective_id = obj["objective"].get("id") or obj["objective"].get("objective_id", "obj-offline")
        except Exception:
            objective_id = "obj-offline"

        agent = MemoryAgent(client, agent_id, objective_id)

        while True:
            try:
                user_input = Prompt.ask("[bold cyan]You[/bold cyan]")
            except (EOFError, KeyboardInterrupt):
                break

            if user_input.strip().lower() in ("quit", "exit", "q"):
                break

            response = agent.respond(user_input)
            console.print(f"\n[bold green]Agent[/bold green]: {response}\n")

        console.print(f"\n[dim]Session ended. {agent.turn} turns. Memories stored in platform.[/dim]")


if __name__ == "__main__":
    run()
