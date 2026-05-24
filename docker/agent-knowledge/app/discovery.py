"""
Model auto-discovery — probes configured providers and writes to discovered_models.

Providers probed:
  Ollama   — GET {OLLAMA_URL}/api/tags   (local, always attempted)
  Anthropic — known model list with published pricing (no API key required to list)
  OpenAI   — GET /v1/models if OPENAI_API_KEY present
  Cohere   — GET /v1/models if COHERE_API_KEY present

Discovery runs at startup and is re-triggered by POST /model-router/discover.
Each run upserts into discovered_models — availability flag updated each probe.
"""

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import httpx

from .db import get_db
from .events import emit

_OLLAMA_URL    = os.getenv("OLLAMA_URL", "http://ollama:11434")
_ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY", "")
_OPENAI_KEY    = os.getenv("OPENAI_API_KEY", "")
_COHERE_KEY    = os.getenv("COHERE_API_KEY", "")

# Fallback catalogue — used ONLY when ANTHROPIC_API_KEY is absent.
# Source: https://docs.anthropic.com/en/docs/about-claude/models/overview
# Keep this list current or it will drift from the live API.
_ANTHROPIC_FALLBACK: List[Dict[str, Any]] = [
    {
        "model_id": "claude-opus-4-7",
        "display_name": "Claude Opus 4.7",
        "model_family": "claude-4",
        "context_window": 200_000,
        "input_modalities": ["text", "image"],
        "output_modalities": ["text"],
        "capabilities": {"reasoning": True, "code": True, "vision": True, "function_calling": True, "streaming": True},
        "cost_per_1k_input": 0.015,
        "cost_per_1k_output": 0.075,
        "max_output_tokens": 32_000,
        "is_local": False,
    },
    {
        "model_id": "claude-sonnet-4-6",
        "display_name": "Claude Sonnet 4.6",
        "model_family": "claude-4",
        "context_window": 200_000,
        "input_modalities": ["text", "image"],
        "output_modalities": ["text"],
        "capabilities": {"reasoning": True, "code": True, "vision": True, "function_calling": True, "streaming": True},
        "cost_per_1k_input": 0.003,
        "cost_per_1k_output": 0.015,
        "max_output_tokens": 16_000,
        "is_local": False,
    },
    {
        "model_id": "claude-haiku-4-5-20251001",
        "display_name": "Claude Haiku 4.5",
        "model_family": "claude-4",
        "context_window": 200_000,
        "input_modalities": ["text", "image"],
        "output_modalities": ["text"],
        "capabilities": {"reasoning": False, "code": True, "vision": True, "function_calling": True, "streaming": True},
        "cost_per_1k_input": 0.0008,
        "cost_per_1k_output": 0.004,
        "max_output_tokens": 8_192,
        "is_local": False,
    },
]


async def run_discovery() -> Dict[str, Any]:
    """Probe all configured providers. Returns summary of found models."""
    results: Dict[str, List[str]] = {
        "ollama": [],
        "anthropic": [],
        "openai": [],
        "cohere": [],
    }

    await _probe_ollama(results)
    await _probe_anthropic(results)
    if _OPENAI_KEY:
        await _probe_openai(results)
    if _COHERE_KEY:
        await _probe_cohere(results)

    total = sum(len(v) for v in results.values())
    await emit("platform", "model-router", "discovery_completed", {
        "total": total,
        "by_provider": {k: len(v) for k, v in results.items()},
    })
    return {"discovered": total, "by_provider": {k: len(v) for k, v in results.items()}, "models": results}


async def list_discovered(provider: Optional[str] = None, available_only: bool = True) -> List[Dict[str, Any]]:
    async with get_db() as db:
        if provider:
            results = await db.query(
                "SELECT * FROM discovered_models WHERE provider = $p AND is_available = $a ORDER BY model_id",
                {"p": provider, "a": available_only},
            )
        elif available_only:
            results = await db.query(
                "SELECT * FROM discovered_models WHERE is_available = true ORDER BY provider, model_id",
            )
        else:
            results = await db.query("SELECT * FROM discovered_models ORDER BY provider, model_id")
    return [_norm(r) for r in _rows(results)]


async def get_model(model_id: str, provider: Optional[str] = None) -> Optional[Dict[str, Any]]:
    async with get_db() as db:
        if provider:
            results = await db.query(
                "SELECT * FROM discovered_models WHERE model_id = $m AND provider = $p LIMIT 1",
                {"m": model_id, "p": provider},
            )
        else:
            results = await db.query(
                "SELECT * FROM discovered_models WHERE model_id = $m LIMIT 1",
                {"m": model_id},
            )
    rows = _rows(results)
    return _norm(rows[0]) if rows else None


# ── Provider probes ───────────────────────────────────────────────────────────

async def _probe_ollama(results: Dict[str, List[str]]) -> None:
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(f"{_OLLAMA_URL}/api/tags")
            if r.status_code != 200:
                return
            data = r.json()
    except Exception:
        # Mark all previously discovered ollama models as unavailable
        await _mark_provider_unavailable("ollama")
        return

    models = data.get("models", [])
    for m in models:
        name = m.get("name", "")
        model_id = name.split(":")[0] if ":" in name else name
        details = m.get("details", {})
        record = {
            "model_id": name,          # full tag e.g. llama3:8b
            "provider": "ollama",
            "display_name": name,
            "model_family": model_id,
            "context_window": None,
            "input_modalities": ["text"],
            "output_modalities": ["text"],
            "capabilities": {
                "reasoning": False,
                "code": "code" in model_id.lower(),
                "vision": "vision" in model_id.lower() or "llava" in model_id.lower(),
                "function_calling": False,
                "streaming": True,
            },
            "cost_per_1k_input": 0.0,
            "cost_per_1k_output": 0.0,
            "max_output_tokens": None,
            "is_local": True,
            "is_available": True,
            "last_seen": _now(),
            "metadata": {"size": m.get("size"), "parameter_size": details.get("parameter_size")},
        }
        await _upsert_model(record)
        results["ollama"].append(name)


async def _probe_anthropic(results: Dict[str, List[str]]) -> None:
    if _ANTHROPIC_KEY:
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                r = await client.get(
                    "https://api.anthropic.com/v1/models",
                    headers={"x-api-key": _ANTHROPIC_KEY, "anthropic-version": "2023-06-01"},
                )
                if r.status_code == 200:
                    for m in r.json().get("data", []):
                        mid = m.get("id", "")
                        if not mid:
                            continue
                        record = {
                            "model_id": mid,
                            "provider": "anthropic",
                            "display_name": m.get("display_name", mid),
                            "model_family": mid.rsplit("-", 1)[0] if "-" in mid else mid,
                            "context_window": m.get("context_window"),
                            "input_modalities": ["text", "image"],
                            "output_modalities": ["text"],
                            "capabilities": {
                                "reasoning": "opus" in mid or "sonnet" in mid,
                                "code": True,
                                "vision": True,
                                "function_calling": True,
                                "streaming": True,
                            },
                            "cost_per_1k_input": 0.0,
                            "cost_per_1k_output": 0.0,
                            "max_output_tokens": None,
                            "is_local": False,
                            "is_available": True,
                            "last_seen": _now(),
                            "metadata": {"created_at": m.get("created_at")},
                        }
                        await _upsert_model(record)
                        results["anthropic"].append(mid)
                    return
        except Exception:
            pass  # fall through to static fallback

    # No key or API unreachable — use static fallback
    for spec in _ANTHROPIC_FALLBACK:
        record = {
            **spec,
            "provider": "anthropic",
            "is_available": True,
            "last_seen": _now(),
            "metadata": {},
        }
        await _upsert_model(record)
        results["anthropic"].append(spec["model_id"])


async def _probe_openai(results: Dict[str, List[str]]) -> None:
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(
                "https://api.openai.com/v1/models",
                headers={"Authorization": f"Bearer {_OPENAI_KEY}"},
            )
            if r.status_code != 200:
                return
            data = r.json()
    except Exception:
        await _mark_provider_unavailable("openai")
        return

    gpt_models = [m for m in data.get("data", []) if "gpt" in m.get("id", "")]
    for m in gpt_models:
        mid = m["id"]
        record = {
            "model_id": mid,
            "provider": "openai",
            "display_name": mid,
            "model_family": mid.split("-")[0] if "-" in mid else mid,
            "context_window": None,
            "input_modalities": ["text", "image"] if "vision" in mid or "4o" in mid else ["text"],
            "output_modalities": ["text"],
            "capabilities": {
                "reasoning": "o1" in mid or "o3" in mid,
                "code": True,
                "vision": "vision" in mid or "4o" in mid,
                "function_calling": True,
                "streaming": True,
            },
            "cost_per_1k_input": 0.0,
            "cost_per_1k_output": 0.0,
            "is_local": False,
            "is_available": True,
            "last_seen": _now(),
            "metadata": {},
        }
        await _upsert_model(record)
        results["openai"].append(mid)


async def _probe_cohere(results: Dict[str, List[str]]) -> None:
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(
                "https://api.cohere.com/v1/models",
                headers={"Authorization": f"Bearer {_COHERE_KEY}"},
            )
            if r.status_code != 200:
                return
            data = r.json()
    except Exception:
        await _mark_provider_unavailable("cohere")
        return

    for m in data.get("models", []):
        mid = m.get("name", "")
        record = {
            "model_id": mid,
            "provider": "cohere",
            "display_name": m.get("name", mid),
            "model_family": mid.split("-")[0] if "-" in mid else mid,
            "context_window": m.get("context_length"),
            "input_modalities": ["text"],
            "output_modalities": ["text"],
            "capabilities": {
                "reasoning": False,
                "code": "command" in mid.lower(),
                "vision": False,
                "function_calling": True,
                "streaming": True,
            },
            "cost_per_1k_input": 0.0,
            "cost_per_1k_output": 0.0,
            "is_local": False,
            "is_available": True,
            "last_seen": _now(),
            "metadata": {},
        }
        await _upsert_model(record)
        results["cohere"].append(mid)


async def _upsert_model(record: Dict[str, Any]) -> None:
    async with get_db() as db:
        existing = await db.query(
            "SELECT id FROM discovered_models WHERE model_id = $m AND provider = $p LIMIT 1",
            {"m": record["model_id"], "p": record["provider"]},
        )
        rows = _rows(existing)
        if rows:
            rid = str(rows[0]["id"])
            await db.merge(rid, {
                "is_available": record.get("is_available", True),
                "last_seen": record.get("last_seen", _now()),
                "metadata": record.get("metadata", {}),
                "capabilities": record.get("capabilities", {}),
            })
        else:
            await db.create("discovered_models", record)


async def _mark_provider_unavailable(provider: str) -> None:
    async with get_db() as db:
        await db.query(
            "UPDATE discovered_models SET is_available = false WHERE provider = $p",
            {"p": provider},
        )


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _rows(result: Any) -> List[Dict[str, Any]]:
    if not result:
        return []
    if isinstance(result, list) and result and isinstance(result[0], dict):
        return result[0].get("result", result)
    return result if isinstance(result, list) else []


def _norm(record: Dict[str, Any]) -> Dict[str, Any]:
    if "id" in record:
        record["id"] = str(record["id"])
    return record
