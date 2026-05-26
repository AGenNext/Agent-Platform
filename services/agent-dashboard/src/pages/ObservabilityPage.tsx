import { useEffect, useState } from "react";

const BASE = "/api";

interface MetricSummary {
  name: string;
  count: number;
  total: number;
  avg: number;
  max: number;
  min: number;
}

interface MetricBucket {
  bucket: string;
  total: number;
  avg: number;
  max: number;
  count: number;
}

interface LatencyRow {
  model_id: string;
  provider?: string;
  p50_ms: number;
  avg_ms: number;
  max_ms: number;
  avg_ttft_ms?: number;
  total_tokens_in: number;
  total_tokens_out: number;
  requests: number;
  errors: number;
}

interface AgentStatusRow {
  tenant_id: string;
  status: string;
  agent_count: number;
}

interface SpendRow {
  tenant_id: string;
  day: number;
  month: number;
  year: number;
  spend_usd: number;
  total_tokens: number;
  call_count: number;
}

interface TrustRow {
  agent_id: string;
  eval_status: string;
  total: number;
  avg_score: number;
}

interface ModelLeaderRow {
  model_id: string;
  provider?: string;
  total_spend_usd: number;
  avg_cost_per_call: number;
  total_tokens_in: number;
  total_tokens_out: number;
  call_count: number;
}

const STATUS_COLORS: Record<string, string> = {
  active: "var(--success)",
  idle: "var(--accent)",
  degraded: "#f97316",
  offline: "var(--error)",
  registered: "var(--text-muted)",
};

async function get<T>(path: string, params?: Record<string, string>): Promise<T> {
  const q = params ? "?" + new URLSearchParams(params).toString() : "";
  const r = await fetch(`${BASE}${path}${q}`, { headers: { "Content-Type": "application/json" } });
  if (!r.ok) throw new Error(`${r.status}`);
  return r.json();
}

async function post<T>(path: string, body: unknown): Promise<T> {
  const r = await fetch(`${BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!r.ok) throw new Error(`${r.status}`);
  return r.json();
}

// Tiny sparkline using inline SVG
function Sparkline({ buckets, field = "avg" }: { buckets: MetricBucket[]; field?: keyof MetricBucket }) {
  if (buckets.length < 2) return <span style={{ color: "var(--text-muted)", fontSize: 11 }}>no data</span>;
  const vals = buckets.map((b) => Number(b[field]) || 0);
  const max = Math.max(...vals, 0.001);
  const W = 120, H = 32;
  const pts = vals.map((v, i) => `${(i / (vals.length - 1)) * W},${H - (v / max) * H}`).join(" ");
  return (
    <svg width={W} height={H} style={{ display: "block" }}>
      <polyline points={pts} fill="none" stroke="var(--accent)" strokeWidth={1.5} strokeLinejoin="round" />
    </svg>
  );
}

export function ObservabilityPage() {
  const [tenantId, setTenantId] = useState("tenant-default");
  const [window_, setWindow] = useState("24h");
  const [loading, setLoading] = useState(false);

  const [metricSummary, setMetricSummary] = useState<MetricSummary[]>([]);
  const [latency, setLatency] = useState<LatencyRow[]>([]);
  const [agentStatus, setAgentStatus] = useState<AgentStatusRow[]>([]);
  const [spend, setSpend] = useState<SpendRow[]>([]);
  const [trust, setTrust] = useState<TrustRow[]>([]);
  const [leaderboard, setLeaderboard] = useState<ModelLeaderRow[]>([]);

  // Sparkline selection
  const [selectedMetric, setSelectedMetric] = useState<string | null>(null);
  const [buckets, setBuckets] = useState<MetricBucket[]>([]);

  // Emit metric form
  const [emitName, setEmitName] = useState("tokens_out");
  const [emitValue, setEmitValue] = useState("1000");
  const [emitUnit, setEmitUnit] = useState("tokens");

  const loadAll = async () => {
    setLoading(true);
    const p: Record<string, string> = { window: window_ };
    if (tenantId) p.tenant_id = tenantId;
    try {
      const [ms, lat, as_, sp, tr, lb] = await Promise.allSettled([
        get<MetricSummary[]>("/observability/metrics/summary", p),
        get<LatencyRow[]>("/observability/latency/p95", p),
        get<AgentStatusRow[]>("/observability/views/agent-status", tenantId ? { tenant_id: tenantId } : {}),
        get<SpendRow[]>("/observability/views/daily-spend", tenantId ? { tenant_id: tenantId } : {}),
        get<TrustRow[]>("/observability/views/trust-stats"),
        get<ModelLeaderRow[]>("/observability/views/model-leaderboard"),
      ]);
      if (ms.status === "fulfilled") setMetricSummary(ms.value);
      if (lat.status === "fulfilled") setLatency(lat.value);
      if (as_.status === "fulfilled") setAgentStatus(as_.value);
      if (sp.status === "fulfilled") setSpend(sp.value);
      if (tr.status === "fulfilled") setTrust(tr.value);
      if (lb.status === "fulfilled") setLeaderboard(lb.value);
    } finally {
      setLoading(false);
    }
  };

  const loadBuckets = async (name: string) => {
    setSelectedMetric(name);
    try {
      const data = await get<MetricBucket[]>("/observability/metrics/buckets", {
        name,
        window: window_,
        bucket: "5m",
        ...(tenantId ? { tenant_id: tenantId } : {}),
      });
      setBuckets(data);
    } catch {
      setBuckets([]);
    }
  };

  const emitMetric = async () => {
    try {
      await post("/observability/metrics", {
        name: emitName,
        value: parseFloat(emitValue),
        unit: emitUnit || undefined,
        tenant_id: tenantId || undefined,
      });
      loadAll();
    } catch (e) {
      alert(String(e));
    }
  };

  useEffect(() => { loadAll(); }, []);

  // Aggregate agent counts by status
  const agentTotals: Record<string, number> = {};
  for (const row of agentStatus) {
    agentTotals[row.status] = (agentTotals[row.status] || 0) + row.agent_count;
  }
  const totalAgents = Object.values(agentTotals).reduce((a, b) => a + b, 0);

  const totalSpend = spend.reduce((s, r) => s + (r.spend_usd || 0), 0);
  const trustPassed = trust.filter((t) => t.eval_status === "passed").reduce((s, r) => s + r.total, 0);
  const trustTotal = trust.reduce((s, r) => s + r.total, 0);

  const card = (label: string, value: string | number, sub?: string) => (
    <div key={label} style={{
      background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8,
      padding: "12px 16px", flex: 1,
    }}>
      <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 4 }}>{label}</div>
      <div style={{ fontSize: 22, fontWeight: 700 }}>{value}</div>
      {sub && <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>{sub}</div>}
    </div>
  );

  return (
    <div>
      {/* Header */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>Observability</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-muted)", fontSize: 13 }}>
            Live views from SurrealDB materialized aggregations — no ETL
          </p>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <input
            placeholder="Tenant ID"
            value={tenantId}
            onChange={(e) => setTenantId(e.target.value)}
            style={{
              padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)",
              background: "var(--surface-2)", color: "var(--text)", fontSize: 13, width: 160,
            }}
          />
          <select value={window_} onChange={(e) => setWindow(e.target.value)}
            style={{
              padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)",
              background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
            }}
          >
            {["1h", "6h", "24h", "7d", "30d"].map((w) => <option key={w} value={w}>{w}</option>)}
          </select>
          <button onClick={loadAll} style={{
            padding: "6px 14px", borderRadius: 6, border: "1px solid var(--border)",
            background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13,
          }}>
            {loading ? "…" : "Refresh"}
          </button>
        </div>
      </div>

      {/* KPI row */}
      <div style={{ display: "flex", gap: 12, marginBottom: 20 }}>
        {card("Agents", totalAgents, Object.entries(agentTotals).map(([s, n]) => `${n} ${s}`).join(" · "))}
        {card("Total spend", `$${totalSpend.toFixed(4)}`, `last ${window_}`)}
        {card("Trust pass rate", trustTotal ? `${Math.round((trustPassed / trustTotal) * 100)}%` : "—", `${trustPassed}/${trustTotal} evals`)}
        {card("Metric series", metricSummary.length, `in last ${window_}`)}
      </div>

      {/* Agent status breakdown */}
      {Object.keys(agentTotals).length > 0 && (
        <div style={{
          background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8,
          padding: "14px 16px", marginBottom: 16,
        }}>
          <div style={{ fontWeight: 600, marginBottom: 10 }}>Agent Status</div>
          <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
            {Object.entries(agentTotals).map(([status, count]) => (
              <div key={status} style={{ display: "flex", alignItems: "center", gap: 6 }}>
                <div style={{
                  width: 10, height: 10, borderRadius: "50%",
                  background: STATUS_COLORS[status] ?? "var(--text-muted)",
                }} />
                <span style={{ fontSize: 13 }}>{status}</span>
                <span style={{ fontSize: 13, fontWeight: 700 }}>{count}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Two-col: metrics + latency */}
      <div style={{ display: "flex", gap: 16, marginBottom: 16 }}>

        {/* Metric summary */}
        <div style={{
          flex: 1, background: "var(--surface)", border: "1px solid var(--border)",
          borderRadius: 8, padding: "14px 16px",
        }}>
          <div style={{ fontWeight: 600, marginBottom: 10 }}>Metrics ({window_})</div>
          {metricSummary.length === 0 ? (
            <div style={{ color: "var(--text-muted)", fontSize: 13 }}>No metrics emitted yet.</div>
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
              <thead>
                <tr style={{ color: "var(--text-muted)", textAlign: "left" }}>
                  {["Name", "Count", "Avg", "Max", "Sparkline"].map((h) => (
                    <th key={h} style={{ padding: "4px 8px", fontWeight: 500 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {metricSummary.map((m) => (
                  <tr key={m.name}
                    onClick={() => loadBuckets(m.name)}
                    style={{
                      borderTop: "1px solid var(--border)", cursor: "pointer",
                      background: selectedMetric === m.name ? "var(--surface-2)" : "transparent",
                    }}
                  >
                    <td style={{ padding: "6px 8px", fontWeight: 600, color: "var(--accent)" }}>{m.name}</td>
                    <td style={{ padding: "6px 8px" }}>{m.count}</td>
                    <td style={{ padding: "6px 8px" }}>{m.avg?.toFixed(2)}</td>
                    <td style={{ padding: "6px 8px" }}>{m.max?.toFixed(2)}</td>
                    <td style={{ padding: "6px 8px" }}>
                      {selectedMetric === m.name
                        ? <Sparkline buckets={buckets} field="avg" />
                        : <span style={{ color: "var(--text-muted)" }}>click</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          {/* Emit metric form */}
          <div style={{
            marginTop: 14, paddingTop: 12, borderTop: "1px solid var(--border)",
            display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap",
          }}>
            <input value={emitName} onChange={(e) => setEmitName(e.target.value)}
              placeholder="metric name"
              style={{
                padding: "5px 8px", borderRadius: 6, border: "1px solid var(--border)",
                background: "var(--surface-2)", color: "var(--text)", fontSize: 12, width: 130,
              }}
            />
            <input value={emitValue} onChange={(e) => setEmitValue(e.target.value)}
              placeholder="value"
              style={{
                padding: "5px 8px", borderRadius: 6, border: "1px solid var(--border)",
                background: "var(--surface-2)", color: "var(--text)", fontSize: 12, width: 70,
              }}
            />
            <input value={emitUnit} onChange={(e) => setEmitUnit(e.target.value)}
              placeholder="unit"
              style={{
                padding: "5px 8px", borderRadius: 6, border: "1px solid var(--border)",
                background: "var(--surface-2)", color: "var(--text)", fontSize: 12, width: 70,
              }}
            />
            <button onClick={emitMetric} style={{
              padding: "5px 12px", borderRadius: 6, border: "none",
              background: "var(--accent)", color: "#fff", cursor: "pointer", fontSize: 12, fontWeight: 600,
            }}>Emit</button>
          </div>
        </div>

        {/* LLM latency */}
        <div style={{
          flex: 1, background: "var(--surface)", border: "1px solid var(--border)",
          borderRadius: 8, padding: "14px 16px",
        }}>
          <div style={{ fontWeight: 600, marginBottom: 10 }}>LLM Latency by Model ({window_})</div>
          {latency.length === 0 ? (
            <div style={{ color: "var(--text-muted)", fontSize: 13 }}>No latency records yet.</div>
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
              <thead>
                <tr style={{ color: "var(--text-muted)", textAlign: "left" }}>
                  {["Model", "Requests", "Errors", "p50 ms", "Avg ms", "TTFT ms"].map((h) => (
                    <th key={h} style={{ padding: "4px 8px", fontWeight: 500 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {latency.map((row) => {
                  const errRate = row.requests ? row.errors / row.requests : 0;
                  return (
                    <tr key={row.model_id} style={{ borderTop: "1px solid var(--border)" }}>
                      <td style={{ padding: "6px 8px", fontWeight: 600 }}>
                        {row.model_id}
                        {row.provider && <span style={{ color: "var(--text-muted)", fontWeight: 400 }}> · {row.provider}</span>}
                      </td>
                      <td style={{ padding: "6px 8px" }}>{row.requests}</td>
                      <td style={{ padding: "6px 8px", color: errRate > 0.05 ? "var(--error)" : "var(--text)" }}>
                        {row.errors} {errRate > 0 && <span style={{ fontSize: 10 }}>({(errRate * 100).toFixed(1)}%)</span>}
                      </td>
                      <td style={{ padding: "6px 8px" }}>{row.p50_ms?.toFixed(0) ?? "—"}</td>
                      <td style={{ padding: "6px 8px" }}>{row.avg_ms?.toFixed(0) ?? "—"}</td>
                      <td style={{ padding: "6px 8px" }}>{row.avg_ttft_ms?.toFixed(0) ?? "—"}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Daily spend chart (simple bar) */}
      {spend.length > 0 && (
        <div style={{
          background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8,
          padding: "14px 16px", marginBottom: 16,
        }}>
          <div style={{ fontWeight: 600, marginBottom: 10 }}>Daily Spend</div>
          <div style={{ display: "flex", gap: 4, alignItems: "flex-end", height: 60 }}>
            {spend.slice(0, 30).reverse().map((row, i) => {
              const maxSpend = Math.max(...spend.map((r) => r.spend_usd), 0.0001);
              const pct = (row.spend_usd / maxSpend) * 100;
              return (
                <div key={i} title={`${row.year}-${row.month}-${row.day}: $${row.spend_usd?.toFixed(4)}`}
                  style={{
                    flex: 1, minWidth: 4, background: "var(--accent)",
                    height: `${Math.max(pct, 4)}%`, borderRadius: "2px 2px 0 0", opacity: 0.8,
                    transition: "height 0.2s",
                  }}
                />
              );
            })}
          </div>
          <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 4 }}>
            Total: ${totalSpend.toFixed(4)} · {spend.reduce((s, r) => s + r.call_count, 0).toLocaleString()} calls · {spend.reduce((s, r) => s + r.total_tokens, 0).toLocaleString()} tokens
          </div>
        </div>
      )}

      {/* Trust stats + model leaderboard */}
      <div style={{ display: "flex", gap: 16 }}>
        <div style={{
          flex: 1, background: "var(--surface)", border: "1px solid var(--border)",
          borderRadius: 8, padding: "14px 16px",
        }}>
          <div style={{ fontWeight: 600, marginBottom: 10 }}>Trust Evaluation Stats</div>
          {trust.length === 0 ? (
            <div style={{ color: "var(--text-muted)", fontSize: 13 }}>No evaluations yet.</div>
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
              <thead>
                <tr style={{ color: "var(--text-muted)", textAlign: "left" }}>
                  {["Agent", "Status", "Count", "Avg Score"].map((h) => (
                    <th key={h} style={{ padding: "4px 8px", fontWeight: 500 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {trust.map((row, i) => (
                  <tr key={i} style={{ borderTop: "1px solid var(--border)" }}>
                    <td style={{ padding: "6px 8px", fontFamily: "monospace", fontSize: 11 }}>{row.agent_id}</td>
                    <td style={{ padding: "6px 8px" }}>
                      <span style={{
                        fontSize: 10, padding: "2px 6px", borderRadius: 10, fontWeight: 600,
                        background: row.eval_status === "passed" ? "var(--success)22" : "var(--error)22",
                        color: row.eval_status === "passed" ? "var(--success)" : "var(--error)",
                      }}>{row.eval_status}</span>
                    </td>
                    <td style={{ padding: "6px 8px" }}>{row.total}</td>
                    <td style={{ padding: "6px 8px" }}>
                      <span style={{ color: (row.avg_score ?? 0) >= 0.7 ? "var(--success)" : "var(--error)" }}>
                        {row.avg_score?.toFixed(3) ?? "—"}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div style={{
          flex: 1, background: "var(--surface)", border: "1px solid var(--border)",
          borderRadius: 8, padding: "14px 16px",
        }}>
          <div style={{ fontWeight: 600, marginBottom: 10 }}>Model Cost Leaderboard</div>
          {leaderboard.length === 0 ? (
            <div style={{ color: "var(--text-muted)", fontSize: 13 }}>No usage records yet.</div>
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
              <thead>
                <tr style={{ color: "var(--text-muted)", textAlign: "left" }}>
                  {["Model", "Calls", "Total $", "Avg $/call", "Tokens out"].map((h) => (
                    <th key={h} style={{ padding: "4px 8px", fontWeight: 500 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {leaderboard.map((row, i) => (
                  <tr key={i} style={{ borderTop: "1px solid var(--border)" }}>
                    <td style={{ padding: "6px 8px", fontWeight: 600 }}>{row.model_id}</td>
                    <td style={{ padding: "6px 8px" }}>{row.call_count}</td>
                    <td style={{ padding: "6px 8px", fontWeight: 600 }}>${row.total_spend_usd?.toFixed(4)}</td>
                    <td style={{ padding: "6px 8px" }}>${row.avg_cost_per_call?.toFixed(4)}</td>
                    <td style={{ padding: "6px 8px" }}>{row.total_tokens_out?.toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
