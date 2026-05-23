import { useEffect, useRef, useState } from "react";

const BASE = "/api";

interface Session {
  id: string;
  session_id: string;
  agent_id: string;
  tenant_id: string;
  user_id?: string;
  title: string;
  channel: string;
  status: string;
  message_count: number;
  token_count: number;
  model_id?: string;
  started_at: string;
  last_active: string;
}

interface Message {
  id: string;
  role: "user" | "assistant" | "system" | "tool" | "function";
  content: string;
  content_type: string;
  tool_name?: string;
  tokens_in: number;
  tokens_out: number;
  cost_usd: number;
  latency_ms?: number;
  created_at: string;
}

const ROLE_COLORS: Record<string, string> = {
  user: "var(--accent)",
  assistant: "var(--success)",
  system: "var(--text-muted)",
  tool: "#a78bfa",
  function: "#f59e0b",
};

const STATUS_COLORS: Record<string, string> = {
  active: "var(--success)",
  idle: "var(--accent)",
  completed: "var(--text-muted)",
  archived: "var(--text-muted)",
  error: "var(--error)",
};

async function apiFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...opts,
  });
  if (!r.ok) throw new Error(`${r.status} ${r.statusText}`);
  return r.json();
}

export function SessionsPage() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [selected, setSelected] = useState<Session | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(false);
  const [msgLoading, setMsgLoading] = useState(false);
  const [filterAgent, setFilterAgent] = useState("");
  const [filterTenant, setFilterTenant] = useState("");
  const [filterStatus, setFilterStatus] = useState("");

  // New session form
  const [showNew, setShowNew] = useState(false);
  const [newAgentId, setNewAgentId] = useState("");
  const [newTenantId, setNewTenantId] = useState("tenant-default");
  const [newTitle, setNewTitle] = useState("");
  const [newChannel, setNewChannel] = useState("api");

  // New message form
  const [msgContent, setMsgContent] = useState("");
  const [msgRole, setMsgRole] = useState("user");
  const msgEndRef = useRef<HTMLDivElement>(null);

  const loadSessions = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filterAgent) params.set("agent_id", filterAgent);
      if (filterTenant) params.set("tenant_id", filterTenant);
      if (filterStatus) params.set("status", filterStatus);
      const data = await apiFetch<Session[]>(`/sessions/?${params}`);
      setSessions(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (sess: Session) => {
    setMsgLoading(true);
    try {
      const data = await apiFetch<Message[]>(`/sessions/${sess.session_id}/messages`);
      setMessages(data);
    } catch (e) {
      console.error(e);
    } finally {
      setMsgLoading(false);
      setTimeout(() => msgEndRef.current?.scrollIntoView({ behavior: "smooth" }), 50);
    }
  };

  useEffect(() => { loadSessions(); }, []);

  useEffect(() => {
    if (selected) loadMessages(selected);
  }, [selected]);

  const createSession = async () => {
    if (!newAgentId) return;
    try {
      await apiFetch("/sessions/", {
        method: "POST",
        body: JSON.stringify({
          agent_id: newAgentId,
          tenant_id: newTenantId,
          title: newTitle || undefined,
          channel: newChannel,
        }),
      });
      setShowNew(false);
      setNewAgentId("");
      setNewTitle("");
      loadSessions();
    } catch (e) {
      alert(String(e));
    }
  };

  const sendMessage = async () => {
    if (!selected || !msgContent.trim()) return;
    try {
      await apiFetch(`/sessions/${selected.session_id}/messages`, {
        method: "POST",
        body: JSON.stringify({ role: msgRole, content: msgContent }),
      });
      setMsgContent("");
      loadMessages(selected);
      loadSessions();
    } catch (e) {
      alert(String(e));
    }
  };

  const fmtTime = (iso: string) =>
    new Date(iso).toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });

  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>Sessions</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-muted)", fontSize: 13 }}>
            Multi-turn agent conversation threads
          </p>
        </div>
        <button
          onClick={() => setShowNew(true)}
          style={{
            padding: "8px 16px", borderRadius: 6, border: "none",
            background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13,
          }}
        >
          New Session
        </button>
      </div>

      {/* Filters */}
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        {[
          { ph: "Agent ID", val: filterAgent, set: setFilterAgent },
          { ph: "Tenant ID", val: filterTenant, set: setFilterTenant },
        ].map(({ ph, val, set }) => (
          <input
            key={ph}
            placeholder={ph}
            value={val}
            onChange={(e) => set(e.target.value)}
            style={{
              padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)",
              background: "var(--surface-2)", color: "var(--text)", fontSize: 13, flex: 1,
            }}
          />
        ))}
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          style={{
            padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)",
            background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
          }}
        >
          <option value="">All statuses</option>
          {["active", "idle", "completed", "archived", "error"].map((s) => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
        <button
          onClick={loadSessions}
          style={{
            padding: "6px 14px", borderRadius: 6, border: "1px solid var(--border)",
            background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13,
          }}
        >
          Load
        </button>
      </div>

      {/* New session modal */}
      {showNew && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", display: "flex",
          alignItems: "center", justifyContent: "center", zIndex: 100,
        }}>
          <div style={{
            background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 10,
            padding: 24, width: 420,
          }}>
            <h3 style={{ margin: "0 0 16px" }}>New Session</h3>
            {[
              { label: "Agent ID *", val: newAgentId, set: setNewAgentId, ph: "agent-abc123" },
              { label: "Tenant ID", val: newTenantId, set: setNewTenantId, ph: "tenant-default" },
              { label: "Title (optional)", val: newTitle, set: setNewTitle, ph: "Research session" },
            ].map(({ label, val, set, ph }) => (
              <div key={label} style={{ marginBottom: 12 }}>
                <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>{label}</div>
                <input
                  value={val}
                  onChange={(e) => set(e.target.value)}
                  placeholder={ph}
                  style={{
                    width: "100%", padding: "8px 10px", borderRadius: 6,
                    border: "1px solid var(--border)", background: "var(--surface-2)",
                    color: "var(--text)", fontSize: 13, boxSizing: "border-box",
                  }}
                />
              </div>
            ))}
            <div style={{ marginBottom: 12 }}>
              <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>Channel</div>
              <select
                value={newChannel}
                onChange={(e) => setNewChannel(e.target.value)}
                style={{
                  width: "100%", padding: "8px 10px", borderRadius: 6,
                  border: "1px solid var(--border)", background: "var(--surface-2)",
                  color: "var(--text)", fontSize: 13,
                }}
              >
                {["api", "dashboard", "slack", "teams", "webhook", "sdk", "a2a"].map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button onClick={() => setShowNew(false)} style={{
                padding: "8px 14px", borderRadius: 6, border: "1px solid var(--border)",
                background: "transparent", color: "var(--text)", cursor: "pointer",
              }}>Cancel</button>
              <button onClick={createSession} disabled={!newAgentId} style={{
                padding: "8px 16px", borderRadius: 6, border: "none",
                background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600,
              }}>Create</button>
            </div>
          </div>
        </div>
      )}

      {/* Main layout: session list + chat */}
      <div style={{ display: "flex", gap: 16, height: "calc(100vh - 200px)", minHeight: 500 }}>
        {/* Session list */}
        <div style={{
          width: 280, flexShrink: 0, border: "1px solid var(--border)", borderRadius: 8,
          overflow: "auto", background: "var(--surface)",
        }}>
          {loading && <div style={{ padding: 16, color: "var(--text-muted)", fontSize: 13 }}>Loading…</div>}
          {!loading && sessions.length === 0 && (
            <div style={{ padding: 16, color: "var(--text-muted)", fontSize: 13 }}>No sessions found.</div>
          )}
          {sessions.map((sess) => (
            <div
              key={sess.id}
              onClick={() => setSelected(sess)}
              style={{
                padding: "12px 14px",
                borderBottom: "1px solid var(--border)",
                cursor: "pointer",
                background: selected?.session_id === sess.session_id ? "var(--surface-2)" : "transparent",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>
                  {sess.title || sess.session_id.slice(0, 12)}
                </span>
                <span style={{
                  fontSize: 10, padding: "2px 6px", borderRadius: 10,
                  background: STATUS_COLORS[sess.status] + "22",
                  color: STATUS_COLORS[sess.status],
                  fontWeight: 600,
                }}>
                  {sess.status}
                </span>
              </div>
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 3 }}>
                {sess.agent_id} · {sess.channel}
              </div>
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                {sess.message_count} msgs · {fmtTime(sess.last_active)}
              </div>
            </div>
          ))}
        </div>

        {/* Chat panel */}
        <div style={{
          flex: 1, border: "1px solid var(--border)", borderRadius: 8,
          display: "flex", flexDirection: "column", background: "var(--surface)", overflow: "hidden",
        }}>
          {!selected ? (
            <div style={{
              flex: 1, display: "flex", alignItems: "center", justifyContent: "center",
              color: "var(--text-muted)", fontSize: 14,
            }}>
              Select a session to view messages
            </div>
          ) : (
            <>
              {/* Header */}
              <div style={{
                padding: "12px 16px", borderBottom: "1px solid var(--border)",
                display: "flex", justifyContent: "space-between", alignItems: "center",
              }}>
                <div>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{selected.title}</div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)" }}>
                    {selected.agent_id} · {selected.token_count.toLocaleString()} tokens
                    {selected.model_id && ` · ${selected.model_id}`}
                  </div>
                </div>
                <span style={{
                  fontSize: 11, padding: "3px 8px", borderRadius: 10,
                  background: STATUS_COLORS[selected.status] + "22",
                  color: STATUS_COLORS[selected.status], fontWeight: 600,
                }}>
                  {selected.status}
                </span>
              </div>

              {/* Messages */}
              <div style={{ flex: 1, overflow: "auto", padding: "12px 16px" }}>
                {msgLoading && <div style={{ color: "var(--text-muted)", fontSize: 13 }}>Loading…</div>}
                {messages.map((msg) => (
                  <div key={msg.id} style={{ marginBottom: 12 }}>
                    <div style={{ display: "flex", gap: 8, alignItems: "baseline", marginBottom: 2 }}>
                      <span style={{
                        fontSize: 11, fontWeight: 700, color: ROLE_COLORS[msg.role] ?? "var(--text-muted)",
                        textTransform: "uppercase",
                      }}>
                        {msg.role}
                        {msg.tool_name && ` · ${msg.tool_name}`}
                      </span>
                      <span style={{ fontSize: 10, color: "var(--text-muted)" }}>
                        {fmtTime(msg.created_at)}
                        {msg.latency_ms != null && ` · ${msg.latency_ms}ms`}
                        {msg.cost_usd > 0 && ` · $${msg.cost_usd.toFixed(4)}`}
                      </span>
                    </div>
                    <div style={{
                      background: "var(--surface-2)", borderRadius: 6, padding: "8px 12px",
                      fontSize: 13, whiteSpace: "pre-wrap", lineHeight: 1.5,
                    }}>
                      {msg.content}
                    </div>
                  </div>
                ))}
                <div ref={msgEndRef} />
              </div>

              {/* Input */}
              <div style={{ padding: "12px 16px", borderTop: "1px solid var(--border)", display: "flex", gap: 8 }}>
                <select
                  value={msgRole}
                  onChange={(e) => setMsgRole(e.target.value)}
                  style={{
                    padding: "8px 10px", borderRadius: 6, border: "1px solid var(--border)",
                    background: "var(--surface-2)", color: "var(--text)", fontSize: 13, width: 110,
                  }}
                >
                  {["user", "assistant", "system", "tool"].map((r) => (
                    <option key={r} value={r}>{r}</option>
                  ))}
                </select>
                <input
                  placeholder="Type a message…"
                  value={msgContent}
                  onChange={(e) => setMsgContent(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); } }}
                  style={{
                    flex: 1, padding: "8px 12px", borderRadius: 6,
                    border: "1px solid var(--border)", background: "var(--surface-2)",
                    color: "var(--text)", fontSize: 13,
                  }}
                />
                <button
                  onClick={sendMessage}
                  disabled={!msgContent.trim()}
                  style={{
                    padding: "8px 16px", borderRadius: 6, border: "none",
                    background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13,
                  }}
                >
                  Send
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
