import { useState } from "react";
import { api } from "../api/client";
import { Card } from "../components/Card";

interface MemoryRecord {
  id: string;
  agent_id: string;
  tenant_id: string;
  content: string;
  summary?: string;
  memory_type: string;
  importance: number;
  tags: string[];
  access_count: number;
  created_at: string;
}

const MEMORY_TYPES = ["all", "episodic", "semantic", "procedural", "working"] as const;
type MemoryType = typeof MEMORY_TYPES[number];

const TYPE_COLORS: Record<string, string> = {
  episodic:   "#f59e0b",
  semantic:   "#6366f1",
  procedural: "#10b981",
  working:    "#3b82f6",
};

export function MemoryPage() {
  const [agentId, setAgentId] = useState("");
  const [tenantId, setTenantId] = useState("tenant-default");
  const [activeType, setActiveType] = useState<MemoryType>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [memories, setMemories] = useState<MemoryRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Add memory form
  const [addOpen, setAddOpen] = useState(false);
  const [newContent, setNewContent] = useState("");
  const [newType, setNewType] = useState("episodic");
  const [newImportance, setNewImportance] = useState(0.5);
  const [newTags, setNewTags] = useState("");
  const [adding, setAdding] = useState(false);

  async function loadMemories() {
    if (!agentId.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const rows = await api.getAgentMemory(agentId.trim(), tenantId.trim(), {
        memory_type: activeType === "all" ? undefined : activeType,
        limit: 50,
      });
      setMemories(rows);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  async function search() {
    if (!agentId.trim() || !searchQuery.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const rows = await api.searchMemory({
        agent_id: agentId.trim(),
        tenant_id: tenantId.trim(),
        query: searchQuery.trim(),
        memory_type: activeType === "all" ? undefined : activeType,
        limit: 20,
      });
      setMemories(rows);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  async function addMemory(e: React.FormEvent) {
    e.preventDefault();
    if (!agentId.trim() || !newContent.trim()) return;
    setAdding(true);
    try {
      const m = await api.storeMemory({
        agent_id: agentId.trim(),
        tenant_id: tenantId.trim(),
        content: newContent.trim(),
        memory_type: newType,
        importance: newImportance,
        tags: newTags.split(",").map((t) => t.trim()).filter(Boolean),
      });
      setMemories((prev) => [m, ...prev]);
      setNewContent("");
      setNewTags("");
      setAddOpen(false);
    } catch (e) {
      setError(String(e));
    } finally {
      setAdding(false);
    }
  }

  const displayedMemories = activeType === "all"
    ? memories
    : memories.filter((m) => m.memory_type === activeType);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Memory</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Agent memory with BM25 full-text search and MTREE vector similarity. 4 memory types: episodic, semantic, procedural, working.
        </p>
      </div>

      {/* Agent selector */}
      <Card title="Agent">
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr auto", gap: 10, alignItems: "flex-end" }}>
          <Field label="Agent ID">
            <input
              value={agentId}
              onChange={(e) => setAgentId(e.target.value)}
              placeholder="e.g. agent-researcher"
              style={inputStyle}
              onKeyDown={(e) => e.key === "Enter" && loadMemories()}
            />
          </Field>
          <Field label="Tenant ID">
            <input
              value={tenantId}
              onChange={(e) => setTenantId(e.target.value)}
              style={inputStyle}
            />
          </Field>
          <button onClick={loadMemories} disabled={!agentId.trim() || loading} style={primaryBtn}>
            {loading ? "Loading…" : "Load"}
          </button>
        </div>
      </Card>

      {/* Search */}
      <Card title="Search">
        <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && search()}
            placeholder="Full-text search across memory content…"
            style={{ ...inputStyle, flex: 1 }}
          />
          <button onClick={search} disabled={!agentId.trim() || !searchQuery.trim() || loading} style={primaryBtn}>
            Search
          </button>
          {searchQuery && (
            <button
              onClick={() => { setSearchQuery(""); loadMemories(); }}
              style={{ padding: "8px 12px", borderRadius: 7, border: "1px solid var(--border)", background: "transparent", color: "var(--text-muted)", cursor: "pointer" }}
            >
              Clear
            </button>
          )}
        </div>
        <p style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 6 }}>
          Uses BM25 full-text search (SurrealDB native). Provide an embedding via API for vector cosine similarity (MTREE).
        </p>
      </Card>

      {/* Memory type tabs */}
      <div style={{ display: "flex", gap: 6 }}>
        {MEMORY_TYPES.map((t) => (
          <button
            key={t}
            onClick={() => { setActiveType(t); }}
            style={{
              padding: "5px 14px",
              borderRadius: 20,
              border: `1px solid ${activeType === t ? (TYPE_COLORS[t] ?? "var(--accent)") : "var(--border)"}`,
              background: activeType === t ? `${TYPE_COLORS[t] ?? "var(--accent)"}22` : "var(--surface-2)",
              color: activeType === t ? (TYPE_COLORS[t] ?? "var(--accent)") : "var(--text-muted)",
              fontSize: 12,
              fontWeight: activeType === t ? 600 : 400,
              cursor: "pointer",
            }}
          >
            {t}
            {t !== "all" && memories.length > 0 && (
              <span style={{ marginLeft: 5, opacity: 0.7 }}>
                {memories.filter((m) => m.memory_type === t).length}
              </span>
            )}
          </button>
        ))}
        <div style={{ flex: 1 }} />
        <button
          onClick={() => setAddOpen((o) => !o)}
          style={{ padding: "5px 14px", borderRadius: 20, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", fontSize: 12, cursor: "pointer" }}
        >
          + Add memory
        </button>
      </div>

      {/* Add memory form */}
      {addOpen && (
        <Card title="New Memory">
          <form onSubmit={addMemory} style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <Field label="Content">
              <textarea
                value={newContent}
                onChange={(e) => setNewContent(e.target.value)}
                rows={3}
                placeholder="Memory content…"
                style={{ ...inputStyle, resize: "vertical" }}
                required
              />
            </Field>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
              <Field label="Type">
                <select
                  value={newType}
                  onChange={(e) => setNewType(e.target.value)}
                  style={inputStyle}
                >
                  {["episodic", "semantic", "procedural", "working"].map((t) => (
                    <option key={t} value={t}>{t}</option>
                  ))}
                </select>
              </Field>
              <Field label="Importance (0–1)">
                <input
                  type="number"
                  min={0}
                  max={1}
                  step={0.1}
                  value={newImportance}
                  onChange={(e) => setNewImportance(parseFloat(e.target.value))}
                  style={inputStyle}
                />
              </Field>
              <Field label="Tags (comma-separated)">
                <input
                  value={newTags}
                  onChange={(e) => setNewTags(e.target.value)}
                  placeholder="role, context, …"
                  style={inputStyle}
                />
              </Field>
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <button type="submit" disabled={adding || !newContent.trim()} style={primaryBtn}>
                {adding ? "Saving…" : "Save memory"}
              </button>
              <button type="button" onClick={() => setAddOpen(false)} style={{ padding: "8px 14px", borderRadius: 7, border: "1px solid var(--border)", background: "transparent", color: "var(--text-muted)", cursor: "pointer" }}>
                Cancel
              </button>
            </div>
          </form>
        </Card>
      )}

      {error && (
        <div style={{ padding: "10px 14px", borderRadius: 8, border: "1px solid var(--red)", background: "rgba(239,68,68,0.08)", color: "var(--red)", fontSize: 13 }}>
          {error}
        </div>
      )}

      {/* Memory cards */}
      {displayedMemories.length > 0 && (
        <Card title={`Memories (${displayedMemories.length})`}>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {displayedMemories.map((m) => (
              <MemoryCard key={m.id} memory={m} />
            ))}
          </div>
        </Card>
      )}

      {memories.length === 0 && !loading && agentId && (
        <Card title="No memories">
          <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
            No memories found for agent <code>{agentId}</code>. Register an agent first — DEFINE EVENT auto-seeds 3 memories on creation.
          </p>
        </Card>
      )}
    </div>
  );
}

function MemoryCard({ memory: m }: { memory: MemoryRecord }) {
  const [expanded, setExpanded] = useState(false);
  const color = TYPE_COLORS[m.memory_type] ?? "var(--text-muted)";

  return (
    <div
      style={{
        background: "var(--surface-2)",
        border: "1px solid var(--border)",
        borderLeft: `3px solid ${color}`,
        borderRadius: 8,
        padding: 12,
        cursor: "pointer",
      }}
      onClick={() => setExpanded((x) => !x)}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 10 }}>
        <div style={{ flex: 1 }}>
          <p style={{ fontSize: 13, margin: 0, lineHeight: 1.4, overflow: "hidden", display: "-webkit-box", WebkitLineClamp: expanded ? undefined : 2, WebkitBoxOrient: "vertical" }}>
            {m.content}
          </p>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 4, flexShrink: 0 }}>
          <span style={{ fontSize: 10, padding: "2px 7px", borderRadius: 4, background: `${color}22`, color, fontWeight: 600 }}>
            {m.memory_type}
          </span>
          <ImportanceBar value={m.importance} />
        </div>
      </div>

      {expanded && (
        <div style={{ marginTop: 10, display: "flex", flexDirection: "column", gap: 5, fontSize: 12 }}>
          {m.summary && <p style={{ color: "var(--text-muted)", margin: 0 }}>{m.summary}</p>}
          <div style={{ display: "flex", gap: 16, color: "var(--text-muted)" }}>
            <span>access_count: {m.access_count}</span>
            <span>{new Date(m.created_at).toLocaleString()}</span>
          </div>
          {m.tags.length > 0 && (
            <div style={{ display: "flex", gap: 5, flexWrap: "wrap" }}>
              {m.tags.map((tag) => (
                <span key={tag} style={{ fontSize: 10, padding: "1px 6px", borderRadius: 4, border: "1px solid var(--border)", color: "var(--text-muted)" }}>
                  {tag}
                </span>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function ImportanceBar({ value }: { value: number }) {
  const pct = Math.round(value * 100);
  const color = value >= 0.7 ? "var(--green)" : value >= 0.4 ? "var(--accent)" : "var(--text-muted)";
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
      <div style={{ width: 48, height: 4, borderRadius: 2, background: "var(--border)", overflow: "hidden" }}>
        <div style={{ width: `${pct}%`, height: "100%", background: color, borderRadius: 2 }} />
      </div>
      <span style={{ fontSize: 10, color: "var(--text-muted)" }}>{pct}%</span>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
      <label style={{ fontSize: 11, fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em" }}>
        {label}
      </label>
      {children}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: "100%",
  background: "var(--surface-2)",
  border: "1px solid var(--border)",
  borderRadius: 7,
  padding: "8px 12px",
  color: "var(--text)",
  fontSize: 14,
  outline: "none",
  boxSizing: "border-box",
};

const primaryBtn: React.CSSProperties = {
  padding: "8px 18px",
  borderRadius: 7,
  border: "none",
  background: "var(--accent)",
  color: "#fff",
  fontWeight: 600,
  fontSize: 14,
  cursor: "pointer",
  whiteSpace: "nowrap",
};
