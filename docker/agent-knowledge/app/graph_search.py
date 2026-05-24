"""
Graph Search — local (entity traversal) + global (community summary) retrieval.

Local search  (GraphRAG "local"):
  Find entities matching query → BFS expand 1 hop via kb_entity_relation
  → collect chunks containing those entities → return chunks + entity context

Global search (GraphRAG "global"):
  Score kb_communities by query term match against summary + entity_names
  → return top community summaries as context (theme-level understanding)

Hybrid search: combine both, deduplicate chunks, return unified context block.
"""

from typing import Any, Dict, List, Set

from .db import get_db
from .knowledge import search_chunks  # text fallback


async def local_search(
    kb_ids: List[str],
    query: str,
    hop_limit: int = 1,
    chunk_limit: int = 12,
) -> Dict[str, Any]:
    """
    Entity-graph traversal. Returns chunks, matched entities, and 1-hop neighbours.
    Falls back to text search if no entities match.
    """
    terms = [t.lower() for t in query.split() if len(t) >= 3]
    if not terms:
        terms = [query.lower()]

    # 1. Find seed entities matching query terms
    async with get_db() as db:
        entity_results = await db.query(
            "SELECT id, name, description, chunk_ids, entity_type FROM kb_entities "
            "WHERE kb_id INSIDE $kbs",
            {"kbs": kb_ids},
        )
    all_entities = _rows(entity_results)

    seed_entities = [
        e for e in all_entities
        if any(t in (e.get("name") or "").lower() or t in (e.get("description") or "").lower()
               for t in terms)
    ]

    if not seed_entities:
        # No entity match — fall back to text search
        fallback_chunks = await search_chunks(kb_ids, query, limit=chunk_limit)
        return {"mode": "text_fallback", "chunks": fallback_chunks, "entities": [], "neighbours": []}

    # 2. BFS expand via kb_entity_relation
    seed_ids = [str(e["id"]) for e in seed_entities]
    neighbour_entities: List[Dict[str, Any]] = []

    if hop_limit > 0:
        async with get_db() as db:
            # SurrealDB native graph traversal
            for sid in seed_ids[:5]:  # limit traversal to top 5 seeds
                hop_result = await db.query(
                    # type::thing() converts string param to record ID for graph traversal
                    "SELECT ->kb_entity_relation->kb_entities.* AS neighbours FROM type::thing($eid)",
                    {"eid": sid},
                )
                rows = _rows(hop_result)
                if rows and rows[0].get("neighbours"):
                    for n in rows[0]["neighbours"]:
                        if isinstance(n, dict):
                            neighbour_entities.append(_norm(n))

    # 3. Collect chunk IDs from seed + neighbour entities
    all_chunk_ids: Set[str] = set()
    for e in seed_entities + neighbour_entities:
        for cid in (e.get("chunk_ids") or []):
            all_chunk_ids.add(str(cid))

    # 4. Fetch those chunks
    chunks: List[Dict[str, Any]] = []
    if all_chunk_ids:
        async with get_db() as db:
            chunk_result = await db.query(
                "SELECT * FROM kb_chunks WHERE id INSIDE $ids LIMIT $lim",
                {"ids": list(all_chunk_ids), "lim": chunk_limit},
            )
        chunks = [_norm(r) for r in _rows(chunk_result)]

    # If we got entity matches but no chunks, fall back to text
    if not chunks:
        chunks = await search_chunks(kb_ids, query, limit=chunk_limit)

    return {
        "mode": "local",
        "chunks": chunks,
        "entities": [_norm(e) for e in seed_entities],
        "neighbours": neighbour_entities,
    }


async def global_search(
    kb_ids: List[str],
    query: str,
    top_k: int = 5,
) -> Dict[str, Any]:
    """
    Community-summary retrieval. Scores communities by query term overlap.
    Returns summaries as high-level thematic context.
    """
    async with get_db() as db:
        comm_result = await db.query(
            "SELECT * FROM kb_communities WHERE kb_id INSIDE $kbs",
            {"kbs": kb_ids},
        )
    communities = [_norm(r) for r in _rows(comm_result)]

    if not communities:
        return {"mode": "global", "communities": [], "entity_count": 0}

    terms = [t.lower() for t in query.split() if len(t) >= 3] or [query.lower()]

    scored = []
    for c in communities:
        text = " ".join([
            c.get("summary") or "",
            c.get("title") or "",
            " ".join(c.get("entity_names") or []),
        ]).lower()
        score = sum(1 for t in terms if t in text)
        if score > 0:
            scored.append((score, c))

    scored.sort(key=lambda x: x[0], reverse=True)
    top_communities = [c for _, c in scored[:top_k]]

    return {
        "mode": "global",
        "communities": top_communities,
        "entity_count": sum(c.get("entity_count", 0) for c in top_communities),
    }


async def hybrid_search(
    kb_ids: List[str],
    query: str,
    chunk_limit: int = 15,
) -> Dict[str, Any]:
    """
    Combine local (entity graph) + global (community summaries).
    Returns a unified context ready for the generator prompt.
    """
    local = await local_search(kb_ids, query, chunk_limit=chunk_limit)
    global_ = await global_search(kb_ids, query)

    # Deduplicate chunks by id
    seen: Set[str] = set()
    chunks = []
    for c in local["chunks"]:
        cid = str(c.get("id", ""))
        if cid not in seen:
            seen.add(cid)
            chunks.append(c)

    return {
        "mode": "hybrid",
        "chunks": chunks,
        "entities": local.get("entities", []),
        "communities": global_.get("communities", []),
        "has_graph": local["mode"] != "text_fallback",
    }


def build_prompt_context(result: Dict[str, Any]) -> str:
    """
    Convert hybrid_search result into a formatted context block for the LLM prompt.
    Global (community) summaries go first for thematic framing,
    then local chunk excerpts for specific evidence.
    """
    parts: List[str] = []

    # Community summaries (global context)
    communities = result.get("communities", [])
    if communities:
        parts.append("=== Thematic Context (Knowledge Graph Communities) ===")
        for c in communities:
            title = c.get("title") or "Community"
            summary = c.get("summary") or ""
            entities = ", ".join((c.get("entity_names") or [])[:8])
            parts.append(f"[{title}]\n{summary}\nKey entities: {entities}")

    # Chunk excerpts (local context)
    chunks = result.get("chunks", [])
    if chunks:
        parts.append("=== Source Excerpts ===")
        for i, chunk in enumerate(chunks, 1):
            label = chunk.get("source_label") or chunk.get("source_ref") or f"Chunk {i}"
            modality = chunk.get("modality", "text")
            prefix = f"[{i}] Source: {label}" + (f" [{modality}]" if modality != "text" else "")
            parts.append(f"{prefix}\n{(chunk.get('content') or '').strip()}")

    if not parts:
        return "(No relevant knowledge base content found for this topic.)"

    return "\n\n---\n\n".join(parts)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _rows(result: Any):
    if not result:
        return []
    if isinstance(result, list) and result and isinstance(result[0], dict):
        return result[0].get("result", result)
    return result if isinstance(result, list) else []


def _norm(record: Dict[str, Any]) -> Dict[str, Any]:
    if "id" in record:
        record["id"] = str(record["id"])
    return record
