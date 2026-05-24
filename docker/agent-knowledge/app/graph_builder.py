"""
Graph Builder — constructs the entity/relation graph over a knowledge base.

Pipeline (per KB):
  1. For each text chunk: call LLM to extract entities + relations (JSON)
  2. Upsert entities into kb_entities (merge if same name already exists)
  3. RELATE entities via kb_entity_relation edges in SurrealDB
  4. BFS community detection over the entity graph
  5. LLM-generate title + summary for each community
  6. Store communities in kb_communities

Graph search (local + global) lives in graph_search.py.
"""

import json
import os
from collections import defaultdict, deque
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set, Tuple

import httpx

from .db import get_db
from .events import emit

_ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY", "")
_PIPELINE_MODEL = os.getenv("PIPELINE_MODEL", "claude-sonnet-4-6")

# Max chunks to process per graph build (cost guard for large KBs)
_MAX_CHUNKS_PER_BUILD = int(os.getenv("GRAPH_BUILD_MAX_CHUNKS", "200"))
# Max tokens to feed per chunk during extraction
_CHUNK_PREVIEW = 1200


async def build_graph(kb_id: str) -> Dict[str, Any]:
    """
    Full graph build for a KB. Returns summary stats.
    Safe to re-run — existing entities are merged, not duplicated.
    """
    await emit("knowledge_base", kb_id, "graph_build_started", {})

    # Load chunks (text only — graph construction is text-driven)
    async with get_db() as db:
        result = await db.query(
            "SELECT * FROM kb_chunks WHERE kb_id = $k AND (modality = 'text' OR !modality) "
            "ORDER BY seq LIMIT $lim",
            {"k": kb_id, "lim": _MAX_CHUNKS_PER_BUILD},
        )
    chunks = _rows(result)

    if not chunks:
        return {"kb_id": kb_id, "entities": 0, "relations": 0, "communities": 0, "chunks_processed": 0}

    # --- Entity + relation extraction ---
    entity_index: Dict[str, str] = {}  # name → surreal id
    relation_pairs: List[Tuple[str, str, str, str, str]] = []  # (src, type, tgt, desc, chunk_id)

    for chunk in chunks:
        chunk_id = chunk.get("id", "")
        content = (chunk.get("content") or "")[:_CHUNK_PREVIEW]
        if not content.strip():
            continue

        extracted = await _extract(content)
        for ent in extracted.get("entities", []):
            eid = await _upsert_entity(kb_id, ent, chunk_id)
            entity_index[ent["name"]] = eid

        for rel in extracted.get("relations", []):
            src = rel.get("source", "")
            tgt = rel.get("target", "")
            if src and tgt:
                relation_pairs.append((src, rel.get("type", "related_to"), tgt, rel.get("description", ""), chunk_id))

    # --- Create RELATE edges ---
    rel_count = 0
    for src_name, rel_type, tgt_name, desc, chunk_id in relation_pairs:
        src_id = entity_index.get(src_name)
        tgt_id = entity_index.get(tgt_name)
        if src_id and tgt_id and src_id != tgt_id:
            await _upsert_relation(kb_id, src_id, tgt_id, rel_type, desc, chunk_id)
            rel_count += 1

    # --- Community detection (BFS over entity graph) ---
    communities = await _detect_communities(kb_id)

    # --- Summarise each community ---
    comm_count = 0
    for idx, entity_names in enumerate(communities):
        summary, title = await _summarize_community(kb_id, entity_names)
        await _upsert_community(kb_id, idx, entity_names, title, summary)
        comm_count += 1

    # Stamp KB as graph-built
    async with get_db() as db:
        await db.query(
            "UPDATE knowledge_bases SET graph_built = true, graph_built_at = $t, "
            "entity_count = $e, community_count = $c, updated_at = $t "
            "WHERE id = $kb OR string::concat('knowledge_bases:', $kb) = string($kb)",
            {"kb": kb_id, "t": _now(), "e": len(entity_index), "c": comm_count},
        )

    stats = {
        "kb_id": kb_id,
        "chunks_processed": len(chunks),
        "entities": len(entity_index),
        "relations": rel_count,
        "communities": comm_count,
    }
    await emit("knowledge_base", kb_id, "graph_build_complete", stats)
    return stats


async def get_graph_stats(kb_id: str) -> Dict[str, Any]:
    async with get_db() as db:
        e_result = await db.query(
            "SELECT count() AS n FROM kb_entities WHERE kb_id = $k GROUP ALL",
            {"k": kb_id},
        )
        r_result = await db.query(
            "SELECT count() AS n FROM kb_entity_relation WHERE kb_id = $k GROUP ALL",
            {"k": kb_id},
        )
        c_result = await db.query(
            "SELECT count() AS n FROM kb_communities WHERE kb_id = $k GROUP ALL",
            {"k": kb_id},
        )
    def _count(r: Any) -> int:
        rows = _rows(r)
        return rows[0].get("n", 0) if rows else 0
    return {
        "kb_id": kb_id,
        "entity_count": _count(e_result),
        "relation_count": _count(r_result),
        "community_count": _count(c_result),
    }


# ── Entity upsert ─────────────────────────────────────────────────────────────

async def _upsert_entity(kb_id: str, ent: Dict[str, Any], chunk_id: str) -> str:
    name = ent.get("name", "").strip()
    if not name:
        return ""
    async with get_db() as db:
        existing = await db.query(
            "SELECT id FROM kb_entities WHERE kb_id = $k AND name = $n LIMIT 1",
            {"k": kb_id, "n": name},
        )
        rows = _rows(existing)
        if rows:
            eid = str(rows[0]["id"])
            await db.merge(eid, {
                "mention_count": rows[0].get("mention_count", 1) + 1,
                "chunk_ids": list(set(rows[0].get("chunk_ids", []) + [chunk_id])),
                "updated_at": _now(),
            })
            return eid
        else:
            result = await db.create("kb_entities", {
                "kb_id": kb_id,
                "name": name,
                "entity_type": ent.get("type", "concept"),
                "description": ent.get("description"),
                "chunk_ids": [chunk_id] if chunk_id else [],
                "mention_count": 1,
                "created_at": _now(),
                "updated_at": _now(),
            })
            created = _norm(result[0] if isinstance(result, list) else result)
            return created["id"]


async def _upsert_relation(
    kb_id: str, src_id: str, tgt_id: str,
    rel_type: str, description: str, chunk_id: str,
) -> None:
    async with get_db() as db:
        existing = await db.query(
            "SELECT id FROM kb_entity_relation WHERE in = $s AND out = $t AND relation_type = $r LIMIT 1",
            {"s": src_id, "t": tgt_id, "r": rel_type},
        )
        if not _rows(existing):
            await db.query(
                # type::thing() converts string params to record IDs for RELATE
                "RELATE type::thing($src) -> kb_entity_relation -> type::thing($tgt) SET "
                "kb_id = $k, relation_type = $r, description = $d, "
                "chunk_id = $c, weight = 1.0, created_at = time::now()",
                {"src": src_id, "tgt": tgt_id, "k": kb_id,
                 "r": rel_type, "d": description or None, "c": chunk_id or None},
            )


# ── Community detection (BFS connected components) ───────────────────────────

async def _detect_communities(kb_id: str) -> List[List[str]]:
    async with get_db() as db:
        ent_result = await db.query(
            "SELECT id, name FROM kb_entities WHERE kb_id = $k",
            {"k": kb_id},
        )
        rel_result = await db.query(
            "SELECT in, out FROM kb_entity_relation WHERE kb_id = $k",
            {"k": kb_id},
        )
    entities = _rows(ent_result)
    relations = _rows(rel_result)

    # Build id→name and adjacency list
    id_to_name: Dict[str, str] = {str(e["id"]): e["name"] for e in entities}
    adj: Dict[str, Set[str]] = defaultdict(set)
    for rel in relations:
        s, t = str(rel.get("in", "")), str(rel.get("out", ""))
        if s and t:
            adj[s].add(t)
            adj[t].add(s)

    visited: Set[str] = set()
    communities: List[List[str]] = []
    for eid in id_to_name:
        if eid in visited:
            continue
        component: List[str] = []
        queue = deque([eid])
        while queue:
            node = queue.popleft()
            if node in visited:
                continue
            visited.add(node)
            component.append(id_to_name.get(node, node))
            for neighbour in adj.get(node, set()):
                if neighbour not in visited:
                    queue.append(neighbour)
        if component:
            communities.append(component)

    # Sort communities by size descending, cap at 50 communities
    communities.sort(key=len, reverse=True)
    return communities[:50]


async def _upsert_community(
    kb_id: str, idx: int,
    entity_names: List[str],
    title: Optional[str],
    summary: Optional[str],
) -> None:
    async with get_db() as db:
        existing = await db.query(
            "SELECT id FROM kb_communities WHERE kb_id = $k AND community_idx = $i LIMIT 1",
            {"k": kb_id, "i": idx},
        )
        rows = _rows(existing)
        if rows:
            await db.merge(str(rows[0]["id"]), {
                "entity_names": entity_names,
                "entity_count": len(entity_names),
                "title": title,
                "summary": summary,
                "created_at": _now(),
            })
        else:
            await db.create("kb_communities", {
                "kb_id": kb_id,
                "community_idx": idx,
                "title": title,
                "summary": summary,
                "entity_names": entity_names,
                "entity_count": len(entity_names),
                "level": 0,
                "created_at": _now(),
            })


# ── LLM calls ─────────────────────────────────────────────────────────────────

_EXTRACT_SYSTEM = """Extract entities and relations from the text.
Return ONLY valid JSON in this exact format:
{
  "entities": [
    {"name": "string", "type": "person|org|product|concept|event|location|other", "description": "one sentence"}
  ],
  "relations": [
    {"source": "entity_name", "type": "relation_label", "target": "entity_name", "description": "one sentence"}
  ]
}
Rules: 3–15 entities max. 5–20 relations max. Use exact entity names in relations."""

_COMMUNITY_SYSTEM = """Given a cluster of related entities from a knowledge base, write a short community summary.
Return ONLY valid JSON: {"title": "3-6 word title", "summary": "2-3 sentence summary of what this group represents"}"""


async def _extract(text: str) -> Dict[str, Any]:
    if not _ANTHROPIC_KEY:
        return {"entities": [], "relations": []}
    try:
        raw = await _call_llm(_EXTRACT_SYSTEM, f"Text:\n{text}")
        # Strip markdown code fences if present
        raw = raw.strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        return json.loads(raw)
    except Exception:
        return {"entities": [], "relations": []}


async def _summarize_community(kb_id: str, entity_names: List[str]) -> Tuple[Optional[str], Optional[str]]:
    if not _ANTHROPIC_KEY or not entity_names:
        return None, f"Community: {', '.join(entity_names[:5])}"
    try:
        # Get a few chunk excerpts for these entities
        async with get_db() as db:
            result = await db.query(
                "SELECT content FROM kb_chunks WHERE kb_id = $k AND content CONTAINS $q LIMIT 3",
                {"k": kb_id, "q": entity_names[0]},
            )
        excerpts = " ".join(r.get("content", "")[:300] for r in _rows(result))
        prompt = (
            f"Entities in this cluster: {', '.join(entity_names[:20])}\n\n"
            f"Sample context:\n{excerpts[:800]}"
        )
        raw = await _call_llm(_COMMUNITY_SYSTEM, prompt)
        raw = raw.strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        data = json.loads(raw)
        return data.get("summary"), data.get("title")
    except Exception:
        return None, f"Cluster: {', '.join(entity_names[:4])}"


async def _call_llm(system: str, user: str) -> str:
    async with httpx.AsyncClient(timeout=60.0) as client:
        r = await client.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": _ANTHROPIC_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": _PIPELINE_MODEL,
                "max_tokens": 1024,
                "system": system,
                "messages": [{"role": "user", "content": user}],
            },
        )
        r.raise_for_status()
        return r.json()["content"][0]["text"]


# ── Helpers ───────────────────────────────────────────────────────────────────

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
