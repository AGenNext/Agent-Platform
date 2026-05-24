"""
SurrealDB Memory for LangChain — drop-in BaseChatMessageHistory implementation.

Stores conversation turns in the platform `session` + `message` schema.
Each message is a first-class platform record: visible in the Sessions dashboard,
counted toward usage, and searchable via BM25 on content.

Usage with LangChain LCEL:
    from surreal_memory import SurrealChatMessageHistory
    from langchain_core.runnables.history import RunnableWithMessageHistory

    history = SurrealChatMessageHistory(
        session_id="sess-abc123",   # reuse an existing platform session_id
        agent_id="agent-xyz",
        tenant_id="tenant-demo",
        api_url="http://localhost:8000",
    )

    chain_with_history = RunnableWithMessageHistory(
        chain,
        lambda session_id: SurrealChatMessageHistory(session_id=session_id, ...),
        input_messages_key="input",
        history_messages_key="history",
    )

Usage with LangGraph:
    from surreal_memory import SurrealCheckpointer
    graph.compile(checkpointer=SurrealCheckpointer(api_url=..., tenant_id=...))
"""
from __future__ import annotations

import json
from typing import Any, Sequence

import httpx
from langchain_core.chat_history import BaseChatMessageHistory
from langchain_core.messages import (
    AIMessage,
    BaseMessage,
    HumanMessage,
    SystemMessage,
    ToolMessage,
    message_to_dict,
    messages_from_dict,
)

# Optional LangGraph checkpointer (only if langgraph installed)
try:
    from langgraph.checkpoint.base import BaseCheckpointSaver, Checkpoint, CheckpointMetadata, CheckpointTuple
    _HAS_LANGGRAPH = True
except ImportError:
    _HAS_LANGGRAPH = False


ROLE_MAP = {
    "human": "user",
    "ai": "assistant",
    "system": "system",
    "tool": "tool",
    "function": "tool",
}
REVERSE_ROLE_MAP = {v: k for k, v in ROLE_MAP.items()}


class SurrealChatMessageHistory(BaseChatMessageHistory):
    """
    LangChain ChatMessageHistory backed by the AGenNext platform sessions API.

    Every message is stored as a `message` record in SurrealDB.
    The session is auto-created on first use if it doesn't exist.
    """

    def __init__(
        self,
        session_id: str,
        agent_id: str,
        tenant_id: str = "tenant-default",
        api_url: str = "http://localhost:8000",
        model_id: str | None = None,
        channel: str = "sdk",
    ):
        self.session_id = session_id
        self.agent_id = agent_id
        self.tenant_id = tenant_id
        self.api_url = api_url.rstrip("/")
        self.model_id = model_id
        self.channel = channel
        self._http = httpx.Client(timeout=15)
        self._ensure_session()

    def _ensure_session(self):
        """Create the platform session if it doesn't exist yet."""
        r = self._http.get(f"{self.api_url}/sessions/{self.session_id}")
        if r.status_code == 404:
            self._http.post(
                f"{self.api_url}/sessions/",
                json={
                    "agent_id": self.agent_id,
                    "tenant_id": self.tenant_id,
                    "title": f"LangChain session {self.session_id}",
                    "channel": self.channel,
                    "model_id": self.model_id,
                },
            )

    @property
    def messages(self) -> list[BaseMessage]:
        r = self._http.get(f"{self.api_url}/sessions/{self.session_id}/messages")
        if not r.is_success:
            return []
        raw = r.json()
        result = []
        for m in raw:
            role = m.get("role", "user")
            content = m.get("content", "")
            if role == "user":
                result.append(HumanMessage(content=content))
            elif role == "assistant":
                result.append(AIMessage(content=content))
            elif role == "system":
                result.append(SystemMessage(content=content))
            elif role == "tool":
                result.append(ToolMessage(content=content, tool_call_id=m.get("tool_call_id", "")))
        return result

    def add_message(self, message: BaseMessage) -> None:
        role = ROLE_MAP.get(message.type, "user")
        tool_call_id = None
        if isinstance(message, ToolMessage):
            tool_call_id = message.tool_call_id

        self._http.post(
            f"{self.api_url}/sessions/{self.session_id}/messages",
            json={
                "role": role,
                "content": str(message.content),
                "content_type": "text",
                "tool_call_id": tool_call_id,
                "tokens_in": 0,
                "tokens_out": 0,
                "cost_usd": 0.0,
                "model_id": self.model_id,
            },
        )

    def add_messages(self, messages: Sequence[BaseMessage]) -> None:
        for m in messages:
            self.add_message(m)

    def clear(self) -> None:
        self._http.patch(
            f"{self.api_url}/sessions/{self.session_id}/status?status=archived",
        )

    def __del__(self):
        self._http.close()


if _HAS_LANGGRAPH:

    class SurrealCheckpointer(BaseCheckpointSaver):
        """
        LangGraph checkpointer that persists graph state to the platform.

        State is serialized as JSON and stored in a dedicated 'checkpoint' session.
        Supports thread_id-based isolation for multi-user graphs.

        Usage:
            from surreal_memory import SurrealCheckpointer
            checkpointer = SurrealCheckpointer(api_url="http://localhost:8000", tenant_id="tenant-demo")
            graph = builder.compile(checkpointer=checkpointer)

            # Run with thread isolation
            config = {"configurable": {"thread_id": "user-123"}}
            graph.invoke({"messages": [...]}, config=config)
        """

        def __init__(
            self,
            api_url: str = "http://localhost:8000",
            tenant_id: str = "tenant-default",
            agent_id: str = "langgraph-checkpointer",
        ):
            super().__init__()
            self.api_url = api_url.rstrip("/")
            self.tenant_id = tenant_id
            self.agent_id = agent_id
            self._http = httpx.Client(timeout=15)
            self._sessions: dict[str, str] = {}  # thread_id → session_id

        def _get_or_create_session(self, thread_id: str) -> str:
            if thread_id in self._sessions:
                return self._sessions[thread_id]
            session_id = f"ckpt-{thread_id}"
            r = self._http.get(f"{self.api_url}/sessions/{session_id}")
            if r.status_code == 404:
                self._http.post(
                    f"{self.api_url}/sessions/",
                    json={
                        "agent_id": self.agent_id,
                        "tenant_id": self.tenant_id,
                        "title": f"LangGraph checkpoint: {thread_id}",
                        "channel": "langgraph",
                    },
                )
            self._sessions[thread_id] = session_id
            return session_id

        def get_tuple(self, config: dict) -> CheckpointTuple | None:
            thread_id = config.get("configurable", {}).get("thread_id", "default")
            session_id = self._get_or_create_session(thread_id)
            r = self._http.get(f"{self.api_url}/sessions/{session_id}/messages", params={"limit": 1})
            if not r.is_success:
                return None
            msgs = r.json()
            if not msgs:
                return None
            last = msgs[-1]
            try:
                state = json.loads(last.get("content", "{}"))
            except Exception:
                return None
            checkpoint = Checkpoint(
                v=1,
                id=last.get("id", thread_id),
                ts=last.get("created_at", ""),
                channel_values=state.get("channel_values", {}),
                channel_versions=state.get("channel_versions", {}),
                versions_seen=state.get("versions_seen", {}),
                pending_sends=state.get("pending_sends", []),
            )
            metadata = CheckpointMetadata(
                source=state.get("source", "loop"),
                step=state.get("step", 0),
                writes=state.get("writes"),
                parents=state.get("parents", {}),
            )
            return CheckpointTuple(config=config, checkpoint=checkpoint, metadata=metadata)

        def list(self, config: dict, *, filter=None, before=None, limit=None):
            thread_id = config.get("configurable", {}).get("thread_id", "default")
            session_id = self._get_or_create_session(thread_id)
            r = self._http.get(f"{self.api_url}/sessions/{session_id}/messages", params={"limit": limit or 20})
            if not r.is_success:
                return
            for msg in r.json():
                try:
                    state = json.loads(msg.get("content", "{}"))
                except Exception:
                    continue
                checkpoint = Checkpoint(
                    v=1,
                    id=msg.get("id", ""),
                    ts=msg.get("created_at", ""),
                    channel_values=state.get("channel_values", {}),
                    channel_versions=state.get("channel_versions", {}),
                    versions_seen=state.get("versions_seen", {}),
                    pending_sends=state.get("pending_sends", []),
                )
                metadata = CheckpointMetadata(
                    source=state.get("source", "loop"),
                    step=state.get("step", 0),
                    writes=state.get("writes"),
                    parents=state.get("parents", {}),
                )
                yield CheckpointTuple(config=config, checkpoint=checkpoint, metadata=metadata)

        def put(self, config: dict, checkpoint: Checkpoint, metadata: CheckpointMetadata, new_versions: dict) -> dict:
            thread_id = config.get("configurable", {}).get("thread_id", "default")
            session_id = self._get_or_create_session(thread_id)
            state = {
                "channel_values": checkpoint.get("channel_values", {}),
                "channel_versions": checkpoint.get("channel_versions", {}),
                "versions_seen": checkpoint.get("versions_seen", {}),
                "pending_sends": checkpoint.get("pending_sends", []),
                "source": metadata.get("source", "loop"),
                "step": metadata.get("step", 0),
                "writes": metadata.get("writes"),
                "parents": metadata.get("parents", {}),
            }
            self._http.post(
                f"{self.api_url}/sessions/{session_id}/messages",
                json={
                    "role": "system",
                    "content": json.dumps(state, default=str),
                    "content_type": "checkpoint",
                },
            )
            return {**config, "configurable": {**config.get("configurable", {}), "checkpoint_id": checkpoint.get("id", "")}}

        def put_writes(self, config: dict, writes: list, task_id: str) -> None:
            pass

        def __del__(self):
            self._http.close()
