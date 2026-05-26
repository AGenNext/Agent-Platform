"""
Microsoft AutoGen integration with AGenNext Agent Platform.

Shows how to:
  1. Register each AutoGen agent on the platform at startup
  2. Inject platform memory into system prompts before each conversation
  3. Hook reply functions to log every message as a platform trace + memory
  4. Persist conversation summaries as platform artifacts
  5. Log token usage to billing

Install extras:
    pip install pyautogen  (or: pip install autogen-agentchat)

Usage:
    ANTHROPIC_API_KEY=sk-ant-... python src/autogen_integration.py
"""

from __future__ import annotations

import os
import sys
import time
import uuid
from typing import Any

# ── Platform bootstrap ────────────────────────────────────────────────────────
PLATFORM_URL = os.getenv("PLATFORM_URL", "http://localhost:8001")
TENANT = os.getenv("PLATFORM_TENANT", "autogen-demo")

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


def register(agent_id: str, name: str, description: str) -> None:
    _post("/agents", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "name": name,
        "description": description,
        "version": "1.0.0",
        "capabilities": CAPABILITIES,
        "model": "claude-sonnet-4-6",
        "tags": ["autogen"],
    })


def store_memory(agent_id: str, content: str, importance: float = 0.6, tags: list[str] | None = None) -> None:
    _post("/memory/store", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "content": content,
        "memory_type": "episodic",
        "importance": importance,
        "tags": tags or [],
    })


def recall_memory(agent_id: str, query: str, limit: int = 3) -> list[str]:
    try:
        r = _http.get(f"/memory/{agent_id}/search", params={"q": query, "limit": limit})
        r.raise_for_status()
        return [m.get("content", "") for m in r.json()]
    except Exception:
        return []


def create_artifact(agent_id: str, objective_id: str | None, title: str, content: str) -> str:
    resp = _post("/artifacts", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "objective_id": objective_id,
        "title": title,
        "artifact_type": "conversation_summary",
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


def log_usage(agent_id: str, input_tokens: int, output_tokens: int) -> None:
    cost = (input_tokens * 3 + output_tokens * 15) / 1_000_000
    _post("/billing/usage", {
        "agent_id": agent_id,
        "tenant_id": TENANT,
        "model": "claude-sonnet-4-6",
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cost_usd": cost,
    })


# ── AutoGen import guard ──────────────────────────────────────────────────────
try:
    import autogen
    from autogen import AssistantAgent, ConversableAgent, UserProxyAgent
    AUTOGEN_AVAILABLE = True
except ImportError:
    try:
        from autogen_agentchat.agents import AssistantAgent, UserProxyAgent
        import autogen_agentchat as autogen
        AUTOGEN_AVAILABLE = True
    except ImportError:
        AUTOGEN_AVAILABLE = False
        print("autogen not installed — running in stub mode (pip install pyautogen)")


# ── Agent IDs ─────────────────────────────────────────────────────────────────

ASSISTANT_ID = f"autogen-assistant-{uuid.uuid4().hex[:6]}"
CRITIC_ID = f"autogen-critic-{uuid.uuid4().hex[:6]}"
PROXY_ID = f"autogen-proxy-{uuid.uuid4().hex[:6]}"
TRACE_ID = uuid.uuid4().hex


# ── Platform message hook ─────────────────────────────────────────────────────

class PlatformMessageHook:
    """
    Wraps an AutoGen agent's generate_reply to log every exchange on the platform.
    Usage: hook = PlatformMessageHook(agent, agent_id, trace_id)
    Then replace: agent.register_reply(...) or monkey-patch _generate_reply.
    """

    def __init__(self, agent_id: str, trace_id: str) -> None:
        self.agent_id = agent_id
        self.trace_id = trace_id
        self._msg_count = 0

    def on_message(self, role: str, content: str) -> None:
        self._msg_count += 1
        # Store assistant outputs as memory
        if role == "assistant" and len(content) > 20:
            store_memory(
                self.agent_id,
                content[:800],
                importance=0.65,
                tags=["autogen", "conversation"],
            )
        record_trace(
            self.trace_id,
            self.agent_id,
            f"autogen.message.{role}",
            meta={"msg_index": self._msg_count, "chars": len(content)},
        )
        # Rough token estimate for billing
        tokens = len(content.split())
        if role == "assistant":
            log_usage(self.agent_id, input_tokens=tokens // 2, output_tokens=tokens)


# ── Memory-augmented system prompt ────────────────────────────────────────────

def build_system_prompt(base: str, agent_id: str, topic: str) -> str:
    memories = recall_memory(agent_id, topic)
    if not memories:
        return base
    mem_block = "\n".join(f"- {m}" for m in memories)
    return f"{base}\n\nRelevant platform memory (from previous sessions):\n{mem_block}"


# ── AutoGen crew ──────────────────────────────────────────────────────────────

def run_autogen(task: str) -> str:
    print(f"\n[AutoGen → Platform] task:  {task}")
    print(f"[AutoGen → Platform] trace: {TRACE_ID}\n")

    # Register agents on platform
    register(ASSISTANT_ID, "AutoGen Assistant", "Primary analysis and reasoning agent")
    register(CRITIC_ID, "AutoGen Critic", "Reviews and improves assistant output")
    register(PROXY_ID, "AutoGen Proxy", "User proxy that drives the conversation")

    # Create platform objective
    obj = _post("/objectives", {
        "tenant_id": TENANT,
        "agent_id": ASSISTANT_ID,
        "title": f"AutoGen: {task[:60]}",
        "description": task,
        "priority": "high",
    })
    objective_id = obj.get("objective_id")

    if not AUTOGEN_AVAILABLE:
        return _stub_run(task, objective_id)

    model = os.getenv("AUTOGEN_MODEL", "claude-3-5-sonnet-20241022")
    llm_config = {
        "config_list": [{"model": model, "api_key": os.getenv("ANTHROPIC_API_KEY", "")}],
        "cache_seed": None,
    }

    assistant_hook = PlatformMessageHook(ASSISTANT_ID, TRACE_ID)
    critic_hook = PlatformMessageHook(CRITIC_ID, TRACE_ID)

    assistant_system = build_system_prompt(
        "You are a highly capable AI assistant. Provide thorough, accurate, well-reasoned responses. "
        "When you have completed the task, end your message with TERMINATE.",
        ASSISTANT_ID,
        task,
    )

    critic_system = build_system_prompt(
        "You are a rigorous critic. Review the assistant's response for accuracy, completeness, "
        "and clarity. Suggest improvements or approve with LGTM. End with TERMINATE when satisfied.",
        CRITIC_ID,
        task,
    )

    assistant = AssistantAgent(
        name="Assistant",
        system_message=assistant_system,
        llm_config=llm_config,
        max_consecutive_auto_reply=3,
    )

    critic = AssistantAgent(
        name="Critic",
        system_message=critic_system,
        llm_config=llm_config,
        max_consecutive_auto_reply=2,
    )

    proxy = UserProxyAgent(
        name="UserProxy",
        human_input_mode="NEVER",
        max_consecutive_auto_reply=0,
        is_termination_msg=lambda m: "TERMINATE" in m.get("content", ""),
        code_execution_config=False,
    )

    # Hook reply generation to log to platform
    original_assistant_reply = assistant.generate_reply

    def hooked_assistant_reply(messages=None, sender=None, **kwargs):
        reply = original_assistant_reply(messages=messages, sender=sender, **kwargs)
        if reply:
            assistant_hook.on_message("assistant", str(reply))
        return reply

    assistant.generate_reply = hooked_assistant_reply

    original_critic_reply = critic.generate_reply

    def hooked_critic_reply(messages=None, sender=None, **kwargs):
        reply = original_critic_reply(messages=messages, sender=sender, **kwargs)
        if reply:
            critic_hook.on_message("assistant", str(reply))
        return reply

    critic.generate_reply = hooked_critic_reply

    # Run: proxy → assistant → critic (group-style sequential)
    t0 = time.time()

    # Phase 1: proxy asks assistant
    proxy.initiate_chat(
        assistant,
        message=task,
        max_turns=4,
        summary_method="last_msg",
    )
    assistant_output = proxy.last_message(assistant).get("content", "") if hasattr(proxy, "last_message") else ""

    # Phase 2: critic reviews
    proxy.initiate_chat(
        critic,
        message=f"Please review this response:\n\n{assistant_output}\n\nTask was: {task}",
        max_turns=2,
        summary_method="last_msg",
    )
    critic_output = proxy.last_message(critic).get("content", "") if hasattr(proxy, "last_message") else ""

    elapsed_ms = int((time.time() - t0) * 1000)

    # Build final summary
    summary = (
        f"# AutoGen Report\n\n"
        f"**Task:** {task}\n\n"
        f"## Assistant Response\n\n{assistant_output}\n\n"
        f"## Critic Review\n\n{critic_output}"
    )

    # Store on platform
    art_id = create_artifact(ASSISTANT_ID, objective_id, f"AutoGen: {task[:50]}", summary)
    record_trace(TRACE_ID, ASSISTANT_ID, "autogen.conversation.complete",
                 duration_ms=elapsed_ms, meta={"artifact_id": art_id})

    print(f"\n[Platform] artifact: {art_id}  trace: {TRACE_ID}")
    return summary


def _stub_run(task: str, objective_id: str | None) -> str:
    """Runs without autogen installed — demonstrates platform wiring only."""
    print("[stub] AutoGen not installed; showing platform wiring only.\n")

    hook = PlatformMessageHook(ASSISTANT_ID, TRACE_ID)

    for role, content in [
        ("assistant", f"Thorough analysis of '{task}': findings and recommendations provided."),
        ("assistant", f"Critic review of analysis: LGTM — well-reasoned and complete. TERMINATE"),
    ]:
        hook.on_message(role, content)
        print(f"  [stub] {role} message → memory + trace + billing recorded")

    summary = (
        f"# AutoGen Stub Report\n\n**Task:** {task}\n\n"
        "Platform wiring verified. Install pyautogen to run real agents."
    )
    art_id = create_artifact(ASSISTANT_ID, objective_id, f"AutoGen Stub: {task[:50]}", summary)
    record_trace(TRACE_ID, ASSISTANT_ID, "autogen.conversation.complete",
                 meta={"artifact_id": art_id, "stub": True})
    print(f"\n[Platform] artifact: {art_id}  trace: {TRACE_ID}")
    return summary


if __name__ == "__main__":
    task = " ".join(sys.argv[1:]) or "What are the key engineering challenges of building multi-agent AI systems?"
    result = run_autogen(task)
    print("\n" + "═" * 60)
    print(result[:2000])
