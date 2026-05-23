import { useEffect, useState } from "react";

const BASE = "/api";

interface KB {
  id: string;
  kb_id: string;
  tenant_id: string;
  agent_id?: string;
  name: string;
  description?: string;
  kb_type: string;
  embed_model: string;
  embed_dim: number;
  chunk_size: number;
  doc_count: number;
  chunk_count: number;
  total_tokens: number;
  active: boolean;
  created_at: string;
}

interface KBDocument {
  id: string;
  doc_id: string;
  title: string;
  source_url?: string;
  source_type: string;
  status: string;
  chunk_count: number;
  token_count: number;
  created_at: string;
}

interface SearchResult {
  content: string;
  score: number;
  doc_title?: string;
}

const STATUS_DOT: Record<string, string> = {
  pending: "#f59e0b",
  processing: "var(--accent)",
  indexed: "var(--success)",
  failed: "var(--error)",
  archived: "var(--text-muted)",
};

async function apiFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...opts,
  });
  if (!r.ok) throw new Error(`${r.status} ${r.statusText}`);
  return r.json();
}

export function KnowledgeBasePage() {
  const [kbs, setKbs] = useState<KB[]>([]);
  const [selected, setSelected] = useState<KB | null>(null);
  const [docs, setDocs] = useState<KBDocument[]>([]);
  const [loading, setLoading] = useState(false);
  const [filterTenant, setFilterTenant] = useState("tenant-default");

  // New KB form
  const [showNewKb, setShowNewKb] = useState(false);
  const [newName, setNewName] = useState("");
  const [newType, setNewType] = useState("documents");
  const [newAgentId, setNewAgentId] = useState("");
  const [newTenantId, setNewTenantId] = useState("tenant-default");

  // New document form
  const [showNewDoc, setShowNewDoc] = useState(false);
  const [docTitle, setDocTitle] = useState("");
  const [docContent, setDocContent] = useState("");
  const [docType, setDocType] = useState("text");
  const [docUrl, setDocUrl] = useState("");

  // Search
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [searching, setSearching] = useState(false);

  const loadKbs = async () => {
    setLoading(true);
    try {
      const params = filterTenant ? `?tenant_id=${encodeURIComponent(filterTenant)}` : "";
      const data = await apiFetch<KB[]>(`/knowledge${params}`);
      setKbs(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const loadDocs = async (kb: KB) => {
    try {
      const data = await apiFetch<KBDocument[]>(`/knowledge/${kb.kb_id}/documents`);
      setDocs(data);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => { loadKbs(); }, []);
  useEffect(() => { if (selected) loadDocs(selected); }, [selected]);

  const createKb = async () => {
    if (!newName) return;
    try {
      await apiFetch("/knowledge/", {
        method: "POST",
        body: JSON.stringify({
          name: newName,
          tenant_id: newTenantId,
          agent_id: newAgentId || undefined,
          kb_type: newType,
        }),
      });
      setShowNewKb(false);
      setNewName("");
      loadKbs();
    } catch (e) {
      alert(String(e));
    }
  };

  const addDocument = async () => {
    if (!selected || !docTitle || !docContent) return;
    try {
      await apiFetch(`/knowledge/${selected.kb_id}/documents`, {
        method: "POST",
        body: JSON.stringify({
          title: docTitle,
          content: docContent,
          source_type: docType,
          source_url: docUrl || undefined,
          tenant_id: selected.tenant_id,
        }),
      });
      setShowNewDoc(false);
      setDocTitle("");
      setDocContent("");
      setDocUrl("");
      loadDocs(selected);
      loadKbs();
    } catch (e) {
      alert(String(e));
    }
  };

  const search = async () => {
    if (!selected || !query.trim()) return;
    setSearching(true);
    try {
      const data = await apiFetch<SearchResult[]>("/knowledge/search", {
        method: "POST",
        body: JSON.stringify({ kb_id: selected.kb_id, query, limit: 10 }),
      });
      setResults(data);
    } catch (e) {
      console.error(e);
    } finally {
      setSearching(false);
    }
  };

  const deleteKb = async (kb: KB) => {
    if (!confirm(`Delete knowledge base "${kb.name}"?`)) return;
    try {
      await apiFetch(`/knowledge/${kb.kb_id}`, { method: "DELETE" });
      if (selected?.kb_id === kb.kb_id) setSelected(null);
      loadKbs();
    } catch (e) {
      alert(String(e));
    }
  };

  const fmtTime = (iso: string) =>
    new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });

  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>Knowledge Base</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-muted)", fontSize: 13 }}>
            Managed RAG collections — documents, chunks, hybrid retrieval
          </p>
        </div>
        <button
          onClick={() => setShowNewKb(true)}
          style={{
            padding: "8px 16px", borderRadius: 6, border: "none",
            background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13,
          }}
        >
          New Collection
        </button>
      </div>

      {/* Tenant filter */}
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input
          placeholder="Tenant ID"
          value={filterTenant}
          onChange={(e) => setFilterTenant(e.target.value)}
          style={{
            padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)",
            background: "var(--surface-2)", color: "var(--text)", fontSize: 13, width: 200,
          }}
        />
        <button
          onClick={loadKbs}
          style={{
            padding: "6px 14px", borderRadius: 6, border: "1px solid var(--border)",
            background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13,
          }}
        >
          Load
        </button>
      </div>

      {/* New KB modal */}
      {showNewKb && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", display: "flex",
          alignItems: "center", justifyContent: "center", zIndex: 100,
        }}>
          <div style={{
            background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 10,
            padding: 24, width: 400,
          }}>
            <h3 style={{ margin: "0 0 16px" }}>New Knowledge Base</h3>
            {[
              { label: "Name *", val: newName, set: setNewName, ph: "Product docs" },
              { label: "Tenant ID", val: newTenantId, set: setNewTenantId, ph: "tenant-default" },
              { label: "Agent ID (optional)", val: newAgentId, set: setNewAgentId, ph: "agent-abc123" },
            ].map(({ label, val, set, ph }) => (
              <div key={label} style={{ marginBottom: 12 }}>
                <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>{label}</div>
                <input value={val} onChange={(e) => set(e.target.value)} placeholder={ph}
                  style={{
                    width: "100%", padding: "8px 10px", borderRadius: 6,
                    border: "1px solid var(--border)", background: "var(--surface-2)",
                    color: "var(--text)", fontSize: 13, boxSizing: "border-box",
                  }}
                />
              </div>
            ))}
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>Type</div>
              <select value={newType} onChange={(e) => setNewType(e.target.value)}
                style={{
                  width: "100%", padding: "8px 10px", borderRadius: 6,
                  border: "1px solid var(--border)", background: "var(--surface-2)",
                  color: "var(--text)", fontSize: 13,
                }}
              >
                {["documents", "faq", "code", "policies", "runbooks", "product", "custom"].map((t) => (
                  <option key={t} value={t}>{t}</option>
                ))}
              </select>
            </div>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button onClick={() => setShowNewKb(false)} style={{
                padding: "8px 14px", borderRadius: 6, border: "1px solid var(--border)",
                background: "transparent", color: "var(--text)", cursor: "pointer",
              }}>Cancel</button>
              <button onClick={createKb} disabled={!newName} style={{
                padding: "8px 16px", borderRadius: 6, border: "none",
                background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600,
              }}>Create</button>
            </div>
          </div>
        </div>
      )}

      <div style={{ display: "flex", gap: 16 }}>
        {/* KB list */}
        <div style={{ width: 260, flexShrink: 0 }}>
          {loading && <div style={{ color: "var(--text-muted)", fontSize: 13 }}>Loading…</div>}
          {kbs.map((kb) => (
            <div
              key={kb.id}
              onClick={() => { setSelected(kb); setResults([]); }}
              style={{
                padding: "12px 14px", marginBottom: 8, borderRadius: 8,
                border: `1px solid ${selected?.kb_id === kb.kb_id ? "var(--accent)" : "var(--border)"}`,
                background: selected?.kb_id === kb.kb_id ? "var(--surface-2)" : "var(--surface)",
                cursor: "pointer",
              }}
            >
              <div style={{ fontWeight: 600, fontSize: 13 }}>{kb.name}</div>
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                {kb.kb_type} · {kb.embed_model}
              </div>
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                {kb.doc_count} docs · {kb.chunk_count} chunks · {kb.total_tokens.toLocaleString()} tokens
              </div>
              <button
                onClick={(e) => { e.stopPropagation(); deleteKb(kb); }}
                style={{
                  marginTop: 6, fontSize: 10, padding: "2px 6px", borderRadius: 4,
                  border: "1px solid var(--border)", background: "transparent",
                  color: "var(--text-muted)", cursor: "pointer",
                }}
              >
                Delete
              </button>
            </div>
          ))}
          {!loading && kbs.length === 0 && (
            <div style={{ color: "var(--text-muted)", fontSize: 13 }}>No knowledge bases found.</div>
          )}
        </div>

        {/* Detail panel */}
        {selected && (
          <div style={{ flex: 1 }}>
            {/* Stats */}
            <div style={{ display: "flex", gap: 12, marginBottom: 16 }}>
              {[
                { label: "Documents", value: selected.doc_count },
                { label: "Chunks", value: selected.chunk_count },
                { label: "Total tokens", value: selected.total_tokens.toLocaleString() },
                { label: "Chunk size", value: `${selected.chunk_size} tok` },
                { label: "Embed dim", value: selected.embed_dim },
              ].map(({ label, value }) => (
                <div key={label} style={{
                  flex: 1, background: "var(--surface)", border: "1px solid var(--border)",
                  borderRadius: 8, padding: "10px 14px",
                }}>
                  <div style={{ fontSize: 11, color: "var(--text-muted)" }}>{label}</div>
                  <div style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>{value}</div>
                </div>
              ))}
            </div>

            {/* Search */}
            <div style={{
              background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8,
              padding: 16, marginBottom: 16,
            }}>
              <div style={{ fontWeight: 600, marginBottom: 10 }}>Search (BM25)</div>
              <div style={{ display: "flex", gap: 8 }}>
                <input
                  placeholder="Search chunks…"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") search(); }}
                  style={{
                    flex: 1, padding: "8px 12px", borderRadius: 6,
                    border: "1px solid var(--border)", background: "var(--surface-2)",
                    color: "var(--text)", fontSize: 13,
                  }}
                />
                <button onClick={search} disabled={searching || !query.trim()} style={{
                  padding: "8px 16px", borderRadius: 6, border: "none",
                  background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13,
                }}>
                  {searching ? "…" : "Search"}
                </button>
              </div>
              {results.length > 0 && (
                <div style={{ marginTop: 12 }}>
                  {results.map((r, i) => (
                    <div key={i} style={{
                      background: "var(--surface-2)", borderRadius: 6, padding: "8px 12px", marginBottom: 6,
                    }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                        <span style={{ fontSize: 11, color: "var(--text-muted)" }}>
                          {r.doc_title || "Unknown doc"}
                        </span>
                        <span style={{ fontSize: 11, fontWeight: 600, color: "var(--accent)" }}>
                          score {(r.score ?? 0).toFixed(3)}
                        </span>
                      </div>
                      <div style={{ fontSize: 13, lineHeight: 1.5 }}>{r.content}</div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Documents */}
            <div style={{
              background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: 16,
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                <div style={{ fontWeight: 600 }}>Documents</div>
                <button
                  onClick={() => setShowNewDoc(true)}
                  style={{
                    padding: "5px 12px", borderRadius: 6, border: "1px solid var(--border)",
                    background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 12,
                  }}
                >
                  + Add Document
                </button>
              </div>

              {showNewDoc && (
                <div style={{
                  background: "var(--surface-2)", borderRadius: 8, padding: 16, marginBottom: 12,
                  border: "1px solid var(--border)",
                }}>
                  <div style={{ fontWeight: 600, marginBottom: 10 }}>New Document</div>
                  {[
                    { label: "Title *", val: docTitle, set: setDocTitle, ph: "Introduction to SurrealDB" },
                    { label: "Source URL", val: docUrl, set: setDocUrl, ph: "https://..." },
                  ].map(({ label, val, set, ph }) => (
                    <div key={label} style={{ marginBottom: 10 }}>
                      <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>{label}</div>
                      <input value={val} onChange={(e) => set(e.target.value)} placeholder={ph}
                        style={{
                          width: "100%", padding: "7px 10px", borderRadius: 6,
                          border: "1px solid var(--border)", background: "var(--surface)",
                          color: "var(--text)", fontSize: 13, boxSizing: "border-box",
                        }}
                      />
                    </div>
                  ))}
                  <div style={{ marginBottom: 10 }}>
                    <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>Content *</div>
                    <textarea
                      value={docContent}
                      onChange={(e) => setDocContent(e.target.value)}
                      placeholder="Paste document content here…"
                      rows={6}
                      style={{
                        width: "100%", padding: "7px 10px", borderRadius: 6,
                        border: "1px solid var(--border)", background: "var(--surface)",
                        color: "var(--text)", fontSize: 13, resize: "vertical", boxSizing: "border-box",
                      }}
                    />
                  </div>
                  <div style={{ display: "flex", gap: 8 }}>
                    <button onClick={() => setShowNewDoc(false)} style={{
                      padding: "7px 14px", borderRadius: 6, border: "1px solid var(--border)",
                      background: "transparent", color: "var(--text)", cursor: "pointer", fontSize: 13,
                    }}>Cancel</button>
                    <button onClick={addDocument} disabled={!docTitle || !docContent} style={{
                      padding: "7px 14px", borderRadius: 6, border: "none",
                      background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13,
                    }}>Add</button>
                  </div>
                </div>
              )}

              {docs.length === 0 ? (
                <div style={{ color: "var(--text-muted)", fontSize: 13 }}>No documents yet.</div>
              ) : (
                docs.map((doc) => (
                  <div key={doc.id} style={{
                    padding: "10px 12px", borderBottom: "1px solid var(--border)",
                    display: "flex", justifyContent: "space-between", alignItems: "center",
                  }}>
                    <div>
                      <div style={{ fontSize: 13, fontWeight: 600 }}>{doc.title}</div>
                      <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                        {doc.source_type} · {doc.chunk_count} chunks · {fmtTime(doc.created_at)}
                      </div>
                    </div>
                    <span style={{
                      fontSize: 10, padding: "2px 7px", borderRadius: 10, fontWeight: 600,
                      background: STATUS_DOT[doc.status] + "22",
                      color: STATUS_DOT[doc.status],
                    }}>
                      {doc.status}
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
