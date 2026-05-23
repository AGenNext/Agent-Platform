import { useState } from "react";
import { Card } from "../components/Card";

const BASE = "/api";
async function get<T>(path: string): Promise<T> {
  const res = await fetch(`${BASE}${path}`, { headers: { "Content-Type": "application/json" } });
  if (!res.ok) throw new Error(`${res.status}: ${await res.text()}`);
  return res.json();
}
async function post<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
  if (!res.ok) throw new Error(`${res.status}: ${await res.text()}`);
  return res.json();
}

interface Span {
  id: string;
  trace_id: string;
  span_id: string;
  parent_span?: string;
  from_agent?: string;
  to_agent?: string;
  objective_id?: string;
  task_id?: string;
  event_type: string;
  payload?: Record<string, unknown>;
  timestamp: string;
}

const EVENT_TYPES = ["event", "agent_start", "agent_stop", "task_start", "task_end", "handoff", "error", "llm_call", "tool_call"];
const EVENT_COLORS: Record<string, string> = {
  error: "var(--red)",
  handoff: "var(--accent)",
  llm_call: "#f59e0b",
  tool_call: "#8b5cf6",
  agent_start: "var(--green)",
  agent_stop: "var(--text-muted)",
  task_start: "#3b82f6",
  task_end: "#10b981",
  event: "var(--border)",
};

export function TraceLogPage() {
  const [spans, setSpans] = useState<Span[]>([]);
  const [filter, setFilter] = useState({ trace_id: "", objective_id: "", event_type: "" });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedSpan, setSelectedSpan] = useState<Span | null>(null);
  const [loaded, setLoaded] = useState(false);

  // Emit span form
  const [emitOpen, setEmitOpen] = useState(false);
  const [emitForm, setEmitForm] = useState({ from_agent: "", to_agent: "", event_type: "event", objective_id: "", task_id: "", payload_json: "{}" });
  const [emitting, setEmitting] = useState(false);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (filter.trace_id) params.set("trace_id", filter.trace_id);
      if (filter.objective_id) params.set("objective_id", filter.objective_id);
      if (filter.event_type) params.set("event_type", filter.event_type);
      params.set("limit", "200");
      const rows = await get<Span[]>(`/traces/?${params}`);
      setSpans(rows);
      setLoaded(true);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  async function emitSpan(e: React.FormEvent) {
    e.preventDefault();
    setEmitting(true);
    try {
      let payload: Record<string, unknown> | undefined;
      try { payload = JSON.parse(emitForm.payload_json); } catch { payload = undefined; }
      const span = await post<Span>("/traces/", {
        from_agent: emitForm.from_agent || undefined,
        to_agent: emitForm.to_agent || undefined,
        event_type: emitForm.event_type,
        objective_id: emitForm.objective_id || undefined,
        task_id: emitForm.task_id || undefined,
        payload,
      });
      setSpans((prev) => [span, ...prev]);
      setEmitOpen(false);
    } catch (e) {
      setError(String(e));
    } finally {
      setEmitting(false);
    }
  }

  // Group spans by trace_id for the waterfall view
  const byTrace = spans.reduce<Record<string, Span[]>>((acc, s) => {
    (acc[s.trace_id] ??= []).push(s);
    return acc;
  }, {});

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Trace Logs</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          OpenTelemetry-aligned agent run logs. Every LLM call, tool use, A2A handoff, and error emits a span with trace_id + span_id.
        </p>
      </div>

      {/* Filters + actions */}
      <Card title="Filter">
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr auto auto", gap: 10, alignItems: "flex-end" }}>
          <Field label="Trace ID">
            <input value={filter.trace_id} onChange={(e) => setFilter((f) => ({ ...f, trace_id: e.target.value }))} placeholder="trace-uuid" style={inputStyle} />
          </Field>
          <Field label="Objective ID">
            <input value={filter.objective_id} onChange={(e) => setFilter((f) => ({ ...f, objective_id: e.target.value }))} placeholder="objective-uuid" style={inputStyle} />
          </Field>
          <Field label="Event type">
            <select value={filter.event_type} onChange={(e) => setFilter((f) => ({ ...f, event_type: e.target.value }))} style={inputStyle}>
              <option value="">All types</option>
              {EVENT_TYPES.map((t) => <option key={t}>{t}</option>)}
            </select>
          </Field>
          <button onClick={load} disabled={loading} style={primaryBtn}>{loading ? "…" : "Load"}</button>
          <button onClick={() => setEmitOpen((o) => !o)} style={secondaryBtn}>+ Emit span</button>
        </div>
      </Card>

      {/* Emit form */}
      {emitOpen && (
        <Card title="Emit Span">
          <form onSubmit={emitSpan} style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
              <Field label="From agent"><input value={emitForm.from_agent} onChange={(e) => setEmitForm((f) => ({ ...f, from_agent: e.target.value }))} placeholder="agent-id" style={inputStyle} /></Field>
              <Field label="To agent"><input value={emitForm.to_agent} onChange={(e) => setEmitForm((f) => ({ ...f, to_agent: e.target.value }))} placeholder="agent-id" style={inputStyle} /></Field>
              <Field label="Event type">
                <select value={emitForm.event_type} onChange={(e) => setEmitForm((f) => ({ ...f, event_type: e.target.value }))} style={inputStyle}>
                  {EVENT_TYPES.map((t) => <option key={t}>{t}</option>)}
                </select>
              </Field>
              <Field label="Objective ID"><input value={emitForm.objective_id} onChange={(e) => setEmitForm((f) => ({ ...f, objective_id: e.target.value }))} style={inputStyle} /></Field>
              <Field label="Task ID"><input value={emitForm.task_id} onChange={(e) => setEmitForm((f) => ({ ...f, task_id: e.target.value }))} style={inputStyle} /></Field>
            </div>
            <Field label="Payload JSON">
              <textarea value={emitForm.payload_json} onChange={(e) => setEmitForm((f) => ({ ...f, payload_json: e.target.value }))} rows={3} style={{ ...inputStyle, fontFamily: "monospace", fontSize: 12, resize: "vertical" }} />
            </Field>
            <div style={{ display: "flex", gap: 10 }}>
              <button type="submit" disabled={emitting} style={primaryBtn}>{emitting ? "Emitting…" : "Emit"}</button>
              <button type="button" onClick={() => setEmitOpen(false)} style={secondaryBtn}>Cancel</button>
            </div>
          </form>
        </Card>
      )}

      {error && <div style={{ padding: "10px 14px", borderRadius: 8, border: "1px solid var(--red)", color: "var(--red)", fontSize: 13 }}>{error}</div>}

      {/* Stats bar */}
      {loaded && (
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
          <StatChip label="Spans" value={spans.length} />
          <StatChip label="Traces" value={Object.keys(byTrace).length} />
          {Object.entries(
            spans.reduce<Record<string, number>>((acc, s) => { acc[s.event_type] = (acc[s.event_type] ?? 0) + 1; return acc; }, {})
          ).map(([type, count]) => (
            <div key={type} style={{ padding: "4px 10px", borderRadius: 20, border: `1px solid ${EVENT_COLORS[type] ?? "var(--border)"}`, fontSize: 11, color: EVENT_COLORS[type] ?? "var(--text-muted)" }}>
              {type}: {count}
            </div>
          ))}
        </div>
      )}

      {/* Two-panel: trace list + span detail */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 340px", gap: 16, alignItems: "start" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {Object.entries(byTrace).map(([traceId, traceSpans]) => (
            <Card key={traceId} title={`Trace ${traceId.slice(0, 16)}…`}>
              {/* Waterfall */}
              <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
                {traceSpans.map((span, i) => {
                  const color = EVENT_COLORS[span.event_type] ?? "var(--border)";
                  const isSelected = selectedSpan?.id === span.id;
                  return (
                    <div
                      key={span.id}
                      onClick={() => setSelectedSpan(isSelected ? null : span)}
                      style={{
                        display: "flex", gap: 12, alignItems: "flex-start",
                        padding: "7px 10px", cursor: "pointer",
                        background: isSelected ? `${color}18` : "transparent",
                        borderLeft: `3px solid ${isSelected ? color : "var(--border)"}`,
                        borderBottom: i < traceSpans.length - 1 ? "1px solid var(--border)" : "none",
                      }}
                    >
                      <div style={{ width: 8, height: 8, borderRadius: "50%", background: color, marginTop: 4, flexShrink: 0 }} />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: "flex", justifyContent: "space-between", gap: 8 }}>
                          <span style={{ fontSize: 12, fontWeight: 600, color }}>
                            {span.event_type}
                          </span>
                          <span style={{ fontSize: 10, color: "var(--text-muted)", flexShrink: 0 }}>
                            {new Date(span.timestamp).toLocaleTimeString()}
                          </span>
                        </div>
                        <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 1 }}>
                          {span.from_agent && <span>{span.from_agent}</span>}
                          {span.from_agent && span.to_agent && <span style={{ margin: "0 4px" }}>→</span>}
                          {span.to_agent && <span>{span.to_agent}</span>}
                          {span.task_id && <span style={{ marginLeft: 8 }}>task:{span.task_id.slice(0, 8)}</span>}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>
          ))}

          {loaded && spans.length === 0 && (
            <Card title="No spans">
              <p style={{ color: "var(--text-muted)", fontSize: 13 }}>No trace spans found. Agents emit spans via POST /traces/ as they execute.</p>
            </Card>
          )}
        </div>

        {/* Span detail */}
        <div style={{ position: "sticky", top: 20 }}>
          {selectedSpan ? (
            <Card title="Span detail">
              <div style={{ display: "flex", flexDirection: "column", gap: 6, fontSize: 12 }}>
                {[
                  ["trace_id", selectedSpan.trace_id],
                  ["span_id", selectedSpan.span_id],
                  ["parent_span", selectedSpan.parent_span ?? "—"],
                  ["event_type", selectedSpan.event_type],
                  ["from_agent", selectedSpan.from_agent ?? "—"],
                  ["to_agent", selectedSpan.to_agent ?? "—"],
                  ["objective_id", selectedSpan.objective_id ?? "—"],
                  ["task_id", selectedSpan.task_id ?? "—"],
                  ["timestamp", new Date(selectedSpan.timestamp).toLocaleString()],
                ].map(([k, v]) => (
                  <div key={k} style={{ display: "flex", justifyContent: "space-between", padding: "4px 0", borderBottom: "1px solid var(--border)", gap: 8 }}>
                    <span style={{ color: "var(--text-muted)", flexShrink: 0 }}>{k}</span>
                    <code style={{ fontSize: 11, textAlign: "right", wordBreak: "break-all" }}>{String(v)}</code>
                  </div>
                ))}
                {selectedSpan.payload && (
                  <div style={{ marginTop: 8 }}>
                    <div style={{ fontSize: 10, color: "var(--text-muted)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 4 }}>payload</div>
                    <pre style={{ margin: 0, padding: "8px 10px", background: "var(--bg)", borderRadius: 6, fontSize: 11, overflowX: "auto", whiteSpace: "pre-wrap", wordBreak: "break-word" }}>
                      {JSON.stringify(selectedSpan.payload, null, 2)}
                    </pre>
                  </div>
                )}
              </div>
            </Card>
          ) : (
            <div style={{ padding: 30, textAlign: "center", color: "var(--text-muted)", fontSize: 13, border: "1px dashed var(--border)", borderRadius: 10 }}>
              Click a span to inspect it.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
      <label style={{ fontSize: 11, fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em" }}>{label}</label>
      {children}
    </div>
  );
}

function StatChip({ label, value }: { label: string; value: string | number }) {
  return (
    <div style={{ padding: "4px 12px", borderRadius: 20, background: "var(--surface-2)", border: "1px solid var(--border)", fontSize: 12 }}>
      <span style={{ color: "var(--text-muted)" }}>{label}: </span>
      <span style={{ fontWeight: 600 }}>{value}</span>
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: "100%", background: "var(--surface-2)", border: "1px solid var(--border)",
  borderRadius: 7, padding: "8px 12px", color: "var(--text)", fontSize: 14,
  outline: "none", boxSizing: "border-box",
};
const primaryBtn: React.CSSProperties = {
  padding: "8px 18px", borderRadius: 7, border: "none",
  background: "var(--accent)", color: "#fff", fontWeight: 600, fontSize: 14,
  cursor: "pointer", whiteSpace: "nowrap",
};
const secondaryBtn: React.CSSProperties = {
  padding: "8px 14px", borderRadius: 7, border: "1px solid var(--border)",
  background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
  cursor: "pointer", whiteSpace: "nowrap",
};
