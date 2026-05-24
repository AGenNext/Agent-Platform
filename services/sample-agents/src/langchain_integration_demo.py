"""
LangChain + LangGraph integration demo — shows all three integration patterns:

1. SurrealChatMessageHistory  — LCEL chain with persistent history
2. SurrealCheckpointer        — LangGraph state persistence
3. SurrealDB as retriever     — LangChain retriever backed by platform /memory/search

Run:
  export ANTHROPIC_API_KEY=sk-ant-...
  export PLATFORM_API_URL=http://localhost:8000
  python langchain_integration_demo.py
"""
import os
import uuid

from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables.history import RunnableWithMessageHistory
from rich.console import Console
from rich.panel import Panel

from platform_client import PlatformClient
from surreal_memory import SurrealChatMessageHistory

load_dotenv()
console = Console()

API_URL = os.getenv("PLATFORM_API_URL", "http://localhost:8000")
TENANT_ID = os.getenv("PLATFORM_TENANT_ID", "tenant-demo")


# ─── Pattern 1: LCEL chain with SurrealDB message history ────────────────────


def demo_lcel_with_history(client: PlatformClient, agent_id: str):
    console.print(Panel("[bold]Pattern 1: LCEL + SurrealChatMessageHistory[/bold]", expand=False))

    session_id = f"demo-{uuid.uuid4().hex[:8]}"

    def get_history(sid: str) -> SurrealChatMessageHistory:
        return SurrealChatMessageHistory(
            session_id=sid,
            agent_id=agent_id,
            tenant_id=TENANT_ID,
            api_url=API_URL,
            model_id="claude-sonnet-4-6",
        )

    llm = ChatAnthropic(model="claude-sonnet-4-6", max_tokens=512)
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a helpful assistant. Keep responses brief."),
        MessagesPlaceholder(variable_name="history"),
        ("human", "{input}"),
    ])

    chain = prompt | llm | StrOutputParser()
    chain_with_history = RunnableWithMessageHistory(
        chain,
        get_history,
        input_messages_key="input",
        history_messages_key="history",
    )

    config = {"configurable": {"session_id": session_id}}

    turns = [
        "My name is Alex and I work on AI infrastructure.",
        "What's the main use case for SurrealDB in AI systems?",
        "How does that relate to what I do?",  # tests memory — should reference Alex + AI infra
    ]

    for turn in turns:
        console.print(f"\n[cyan]User:[/cyan] {turn}")
        response = chain_with_history.invoke({"input": turn}, config=config)
        console.print(f"[green]Assistant:[/green] {response}")

    console.print(f"\n[dim]Session ID: {session_id} — visible in Sessions dashboard[/dim]")


# ─── Pattern 2: Platform memory as LangChain retriever ───────────────────────


from langchain_core.documents import Document
from langchain_core.retrievers import BaseRetriever


class SurrealMemoryRetriever(BaseRetriever):
    """
    LangChain BaseRetriever backed by platform /memory/search.
    Use in RAG chains to inject agent episodic/semantic memory as context.
    """

    agent_id: str
    tenant_id: str = "tenant-default"
    api_url: str = "http://localhost:8000"
    limit: int = 5
    memory_type: str | None = None

    class Config:
        arbitrary_types_allowed = True

    def _get_relevant_documents(self, query: str, *, run_manager=None) -> list[Document]:
        import httpx
        try:
            r = httpx.post(
                f"{self.api_url}/memory/search",
                json={
                    "agent_id": self.agent_id,
                    "tenant_id": self.tenant_id,
                    "query": query,
                    "limit": self.limit,
                    **({"memory_type": self.memory_type} if self.memory_type else {}),
                },
                timeout=10,
            )
            r.raise_for_status()
            return [
                Document(
                    page_content=m["content"],
                    metadata={
                        "memory_type": m.get("memory_type", "episodic"),
                        "importance": m.get("importance", 0.5),
                        "tags": m.get("tags", []),
                        "created_at": m.get("created_at", ""),
                    },
                )
                for m in r.json()
            ]
        except Exception as e:
            console.print(f"[yellow]Memory retrieval error: {e}[/yellow]")
            return []


def demo_memory_retriever(client: PlatformClient, agent_id: str):
    console.print(Panel("[bold]Pattern 2: SurrealMemoryRetriever[/bold]", expand=False))

    retriever = SurrealMemoryRetriever(
        agent_id=agent_id,
        tenant_id=TENANT_ID,
        api_url=API_URL,
        limit=4,
    )

    llm = ChatAnthropic(model="claude-sonnet-4-6", max_tokens=512)
    prompt = ChatPromptTemplate.from_messages([
        ("system", (
            "You are an assistant with access to memory context.\n"
            "Memory context:\n{memory}\n\n"
            "Answer based on this context when relevant."
        )),
        ("human", "{question}"),
    ])
    chain = prompt | llm | StrOutputParser()

    question = "What do you know about my background and interests?"
    console.print(f"\n[cyan]Question:[/cyan] {question}")

    docs = retriever.get_relevant_documents(question)
    memory_text = "\n".join(f"- {d.page_content}" for d in docs) if docs else "No memories found."
    console.print(f"[dim]Retrieved {len(docs)} memories[/dim]")

    response = chain.invoke({"question": question, "memory": memory_text})
    console.print(f"[green]Answer:[/green] {response}")


# ─── Entry point ───────────────────────────────────────────────────────────────


def run():
    console.print(Panel(
        "[bold blue]LangChain + AGenNext Integration Demo[/bold blue]\n"
        "Shows: LCEL history, memory retriever",
        expand=False,
    ))

    with PlatformClient() as client:
        if not client.health():
            console.print("[yellow]Warning: Platform API not reachable.[/yellow]")

        try:
            agent = client.register_agent(
                name="LangChainDemo-v1",
                description="LangChain integration demo agent",
                version="1.0.0",
                goal_types=["conversation", "demo"],
                skill_ids=["memory_retrieval", "conversation"],
            )
            agent_id = agent.get("agent_id", "langchain-demo")
            console.print(f"[green]Agent:[/green] {agent_id}\n")
        except Exception as e:
            console.print(f"[yellow]Registration skipped: {e}[/yellow]")
            agent_id = "langchain-demo"

        demo_lcel_with_history(client, agent_id)
        console.print()
        demo_memory_retriever(client, agent_id)


if __name__ == "__main__":
    run()
