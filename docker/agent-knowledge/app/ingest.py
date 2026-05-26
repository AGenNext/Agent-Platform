"""
Document Ingestion — split text/files into KB chunks.

Chunking strategies:
  paragraph  — split on blank lines; merge small paragraphs up to chunk_size
  fixed      — sliding window of chunk_size chars with chunk_overlap overlap
  sentence   — split on '. '/'\\n'; merge up to chunk_size

File type support:
  .txt / .md   — raw text, paragraph chunking by default
  .csv         — each row becomes one chunk (header prepended)
  .json        — if list-of-objects, each object becomes a chunk
               — if string/other, treat as raw text
"""

import csv
import io
import json
import re
from typing import Any, Dict, List, Optional, Tuple

from .knowledge import add_chunk


# ── Public API ────────────────────────────────────────────────────────────────

async def ingest_text(
    kb_id: str,
    text: str,
    source_label: str = "",
    source_ref: str = "",
    strategy: str = "paragraph",
    chunk_size: int = 800,
    chunk_overlap: int = 100,
) -> Dict[str, Any]:
    """Chunk raw text and add to KB. Returns ingest summary."""
    chunks = _chunk_text(text, strategy, chunk_size, chunk_overlap)
    return await _store_chunks(kb_id, chunks, source_label, source_ref)


async def ingest_file(
    kb_id: str,
    filename: str,
    content_bytes: bytes,
    source_label: str = "",
    strategy: str = "paragraph",
    chunk_size: int = 800,
    chunk_overlap: int = 100,
) -> Dict[str, Any]:
    """Detect file type, extract text/records, chunk, and add to KB."""
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "txt"
    sl = source_label or filename

    if ext in ("txt", "md", "rst", "log"):
        text = content_bytes.decode("utf-8", errors="replace")
        chunks = _chunk_text(text, strategy, chunk_size, chunk_overlap)

    elif ext == "csv":
        chunks = _chunk_csv(content_bytes)

    elif ext == "json":
        chunks = _chunk_json(content_bytes, chunk_size)

    else:
        # Treat as plain text fallback
        text = content_bytes.decode("utf-8", errors="replace")
        chunks = _chunk_text(text, strategy, chunk_size, chunk_overlap)

    return await _store_chunks(kb_id, chunks, sl, filename)


def preview_chunks(
    text: str,
    strategy: str = "paragraph",
    chunk_size: int = 800,
    chunk_overlap: int = 100,
) -> List[Dict[str, Any]]:
    """Return chunks without storing — used by the preview endpoint."""
    raw = _chunk_text(text, strategy, chunk_size, chunk_overlap)
    return [
        {"seq": i, "content": c, "char_count": len(c)}
        for i, c in enumerate(raw)
    ]


# ── Chunking strategies ───────────────────────────────────────────────────────

def _chunk_text(
    text: str,
    strategy: str,
    chunk_size: int,
    chunk_overlap: int,
) -> List[str]:
    text = text.strip()
    if not text:
        return []

    if strategy == "paragraph":
        return _chunk_paragraph(text, chunk_size)
    if strategy == "sentence":
        return _chunk_sentence(text, chunk_size, chunk_overlap)
    return _chunk_fixed(text, chunk_size, chunk_overlap)


def _chunk_paragraph(text: str, chunk_size: int) -> List[str]:
    """Split on blank lines; merge short paragraphs into the target window."""
    raw_paras = re.split(r"\n{2,}", text)
    paras = [p.strip() for p in raw_paras if p.strip()]

    chunks: List[str] = []
    current_parts: List[str] = []
    current_len = 0

    for para in paras:
        if current_len + len(para) + 1 > chunk_size and current_parts:
            chunks.append("\n\n".join(current_parts))
            current_parts = []
            current_len = 0
        current_parts.append(para)
        current_len += len(para) + 1

        # Paragraph too long — hard split it
        if current_len > chunk_size * 2:
            chunks.append("\n\n".join(current_parts))
            current_parts = []
            current_len = 0

    if current_parts:
        chunks.append("\n\n".join(current_parts))

    return [c for c in chunks if c.strip()]


def _chunk_fixed(text: str, chunk_size: int, overlap: int) -> List[str]:
    """Sliding window over characters."""
    if overlap >= chunk_size:
        overlap = chunk_size // 4

    chunks: List[str] = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end]
        chunks.append(chunk)
        if end >= len(text):
            break
        start += chunk_size - overlap

    return [c for c in chunks if c.strip()]


def _chunk_sentence(text: str, chunk_size: int, overlap: int) -> List[str]:
    """Split on sentence boundaries; merge up to chunk_size."""
    sentences = re.split(r"(?<=[.!?])\s+", text)
    chunks: List[str] = []
    current: List[str] = []
    current_len = 0

    for sent in sentences:
        sent = sent.strip()
        if not sent:
            continue
        if current_len + len(sent) > chunk_size and current:
            chunks.append(" ".join(current))
            # Carry over last overlap chars worth of sentences
            carry_len = 0
            carry: List[str] = []
            for s in reversed(current):
                carry_len += len(s)
                carry.insert(0, s)
                if carry_len >= overlap:
                    break
            current = carry
            current_len = sum(len(s) for s in current)
        current.append(sent)
        current_len += len(sent) + 1

    if current:
        chunks.append(" ".join(current))

    return [c for c in chunks if c.strip()]


def _chunk_csv(content_bytes: bytes) -> List[str]:
    """One chunk per CSV row, with header prepended."""
    try:
        text = content_bytes.decode("utf-8", errors="replace")
        reader = csv.DictReader(io.StringIO(text))
        chunks = []
        headers = reader.fieldnames or []
        for row in reader:
            parts = [f"{k}: {v}" for k, v in row.items() if v and v.strip()]
            if parts:
                chunks.append("\n".join(parts))
        return chunks
    except Exception:
        return [content_bytes.decode("utf-8", errors="replace")]


def _chunk_json(content_bytes: bytes, chunk_size: int) -> List[str]:
    """List-of-objects → one chunk per object; else treat as text."""
    try:
        data = json.loads(content_bytes.decode("utf-8", errors="replace"))
        if isinstance(data, list):
            chunks = []
            for item in data:
                if isinstance(item, dict):
                    text = "\n".join(f"{k}: {v}" for k, v in item.items())
                else:
                    text = str(item)
                chunks.append(text[:chunk_size])
            return [c for c in chunks if c.strip()]
        if isinstance(data, dict):
            text = "\n".join(f"{k}: {v}" for k, v in data.items())
            return _chunk_paragraph(text, chunk_size)
    except Exception:
        pass
    return _chunk_text(content_bytes.decode("utf-8", errors="replace"), "paragraph", chunk_size, 0)


# ── Storage ───────────────────────────────────────────────────────────────────

async def _store_chunks(
    kb_id: str,
    chunks: List[str],
    source_label: str,
    source_ref: str,
) -> Dict[str, Any]:
    stored = 0
    skipped = 0
    for seq, content in enumerate(chunks):
        content = content.strip()
        if not content:
            skipped += 1
            continue
        await add_chunk(
            kb_id=kb_id,
            content=content,
            source_ref=source_ref,
            source_label=source_label,
            seq=seq,
        )
        stored += 1

    return {
        "kb_id": kb_id,
        "chunks_stored": stored,
        "chunks_skipped": skipped,
        "total_input_chunks": len(chunks),
        "source_label": source_label,
    }
