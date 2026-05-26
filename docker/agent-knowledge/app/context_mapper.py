"""
Context Mapper — cross-KB relevance discovery.

Given a topic/query, scans all knowledge bases and scores each one by how
much relevant content it contains (entities + communities + chunks).
Also detects cross-KB entity links — the same entity appearing in multiple KBs.

Returns a ranked context map: which KBs to use, why, and what's inside them.
"""

from typing import Any, Dict, List, Optional

from .db import get_db
from .knowledge import list_knowledge_bases


async def map_context(
    query: str,
    workspace_id: Optional[str] = None,
    top_kbs: int = 10,
) -> Dict[str, Any]:
    """
    Score every KB against the query and return a ranked context map.
    """
    if not query.strip():
        return {"query": query, "kb_maps": [], "cross_links": [], "suggested_kb_ids": []}

    terms = [t.lower() for t in query.split() if len(t) >= 3]
    if not terms:
        terms = [query.lower()]

    kbs = await list_knowledge_bases(workspace_id)
    if not kbs:
        return {"query": query, "kb_maps": [], "cross_links": [], "suggested_kb_ids": []}

    kb_ids = [kb["id"] for kb in kbs]
    kb_by_id = {kb["id"]: kb for kb in kbs}

    # ── Fetch all entities, communities, chunks for these KBs ─────────────────
    async with get_db() as db:
        ent_result  = await db.query(
            "SELECT id, kb_id, name, entity_type, description, chunk_ids, mention_count "
            "FROM kb_entities WHERE kb_id INSIDE $kbs",
            {"kbs": kb_ids},
        )
        comm_result = await db.query(
            "SELECT id, kb_id, title, summary, entity_names, entity_count "
            "FROM kb_communities WHERE kb_id INSIDE $kbs",
            {"kbs": kb_ids},
        )
        chunk_result = await db.query(
            "SELECT id, kb_id, content, source_label, source_ref "
            "FROM kb_chunks WHERE kb_id INSIDE $kbs",
            {"kbs": kb_ids},
        )

    entities   = [_norm(r) for r in _rows(ent_result)]
    communities = [_norm(r) for r in _rows(comm_result)]
    chunks     = [_norm(r) for r in _rows(chunk_result)]

    # ── Score per KB ──────────────────────────────────────────────────────────
    kb_scores: Dict[str, Dict[str, Any]] = {
        kb["id"]: {
            "kb_id":   kb["id"],
            "kb_name": kb["name"],
            "kb_type": kb.get("kb_type", "general"),
            "chunk_count": kb.get("chunk_count", 0),
            "has_graph": False,
            "matched_entities":    [],
            "matched_communities": [],
            "matched_chunks":      [],
        }
        for kb in kbs
    }

    # Score entities
    for e in entities:
        kid = str(e.get("kb_id") or "")
        if kid not in kb_scores:
            continue
        text = f"{e.get('name', '')} {e.get('description', '')}".lower()
        score = sum(1 for t in terms if t in text)
        if score > 0:
            kb_scores[kid]["matched_entities"].append({
                "score": score,
                "name": e.get("name"),
                "entity_type": e.get("entity_type"),
                "description": (e.get("description") or "")[:120],
            })
        if e.get("chunk_ids"):
            kb_scores[kid]["has_graph"] = True

    # Score communities
    for c in communities:
        kid = str(c.get("kb_id") or "")
        if kid not in kb_scores:
            continue
        text = " ".join([
            c.get("title") or "",
            c.get("summary") or "",
            " ".join(c.get("entity_names") or []),
        ]).lower()
        score = sum(1 for t in terms if t in text)
        if score > 0:
            kb_scores[kid]["matched_communities"].append({
                "score": score,
                "title": c.get("title"),
                "summary": (c.get("summary") or "")[:200],
                "entity_count": c.get("entity_count", 0),
            })
        kb_scores[kid]["has_graph"] = True

    # Score chunks
    for ch in chunks:
        kid = str(ch.get("kb_id") or "")
        if kid not in kb_scores:
            continue
        text = (ch.get("content") or "").lower()
        score = sum(1 for t in terms if t in text)
        if score > 0:
            kb_scores[kid]["matched_chunks"].append({
                "score": score,
                "preview": text[:180].replace("\n", " "),
                "source_label": ch.get("source_label") or ch.get("source_ref") or "",
            })

    # ── Compute relevance scores and trim to top previews ─────────────────────
    kb_maps = []
    for kid, d in kb_scores.items():
        ents   = sorted(d["matched_entities"],    key=lambda x: x["score"], reverse=True)
        comms  = sorted(d["matched_communities"], key=lambda x: x["score"], reverse=True)
        chnks  = sorted(d["matched_chunks"],      key=lambda x: x["score"], reverse=True)

        # Weighted relevance: communities > entities > chunks
        raw = (
            len(comms)  * 3
            + len(ents) * 2
            + len(chnks)
        )
        max_possible = max(
            (len(communities) * 3 + len(entities) * 2 + len(chunks)), 1
        )
        relevance = min(round(raw / max_possible, 4), 1.0) if raw > 0 else 0.0

        kb_maps.append({
            "kb_id":   kid,
            "kb_name": d["kb_name"],
            "kb_type": d["kb_type"],
            "chunk_count": d["chunk_count"],
            "has_graph": d["has_graph"],
            "relevance_score": relevance,
            "matched_entity_count":    len(ents),
            "matched_community_count": len(comms),
            "matched_chunk_count":     len(chnks),
            "top_entities":    [_strip_score(e) for e in ents[:5]],
            "top_communities": [_strip_score(c) for c in comms[:3]],
            "top_chunks":      [_strip_score(c) for c in chnks[:3]],
        })

    kb_maps.sort(key=lambda x: x["relevance_score"], reverse=True)
    kb_maps = kb_maps[:top_kbs]

    # ── Cross-KB entity links ─────────────────────────────────────────────────
    entity_kb_map: Dict[str, List[str]] = {}
    for e in entities:
        name = (e.get("name") or "").strip().lower()
        kid  = str(e.get("kb_id") or "")
        if name and kid:
            entity_kb_map.setdefault(name, [])
            if kid not in entity_kb_map[name]:
                entity_kb_map[name].append(kid)

    cross_links = []
    for name, kids in entity_kb_map.items():
        if len(kids) > 1:
            # Only surface cross-links for entities that appear in query context
            if any(t in name for t in terms):
                cross_links.append({
                    "entity_name": name,
                    "kb_ids":  kids,
                    "kb_names": [kb_by_id[k]["name"] for k in kids if k in kb_by_id],
                })

    cross_links.sort(key=lambda x: len(x["kb_ids"]), reverse=True)

    # ── Suggested KB IDs (non-zero relevance, top 5) ──────────────────────────
    suggested_kb_ids = [
        m["kb_id"] for m in kb_maps
        if m["relevance_score"] > 0
    ][:5]

    return {
        "query": query,
        "kb_maps": kb_maps,
        "cross_links": cross_links[:10],
        "suggested_kb_ids": suggested_kb_ids,
    }


# ── Helpers ───────────────────────────────────────────────────────────────────

def _strip_score(d: Dict[str, Any]) -> Dict[str, Any]:
    return {k: v for k, v in d.items() if k != "score"}


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
