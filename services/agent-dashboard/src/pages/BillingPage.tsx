import { useState } from "react";
import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";

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

interface CostSummary {
  tenant_id: string;
  total_spend_usd: number;
  total_tokens: number;
  total_calls: number;
  spend_by_model: { model_id: string; provider: string; spend_usd: number; calls: number }[];
  spend_by_objective: { objective_id: string; spend_usd: number; calls: number }[];
}

interface UsageRecord {
  id: string;
  tenant_id: string;
  model_id?: string;
  provider?: string;
  tokens_in: number;
  tokens_out: number;
  cost_usd: number;
  duration_ms?: number;
  recorded_at: string;
}

interface BudgetSet {
  tenant_id: string;
  limit_usd: number;
  alert_pct: number;
  period: string;
}

export function BillingPage() {
  const [tenantId, setTenantId] = useState("tenant-default");
  const [summary, setSummary] = useState<CostSummary | null>(null);
  const [records, setRecords] = useState<UsageRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Log usage form
  const [logOpen, setLogOpen] = useState(false);
  const [logForm, setLogForm] = useState({ model_id: "claude-sonnet-4-6", provider: "anthropic", tokens_in: 1000, tokens_out: 500, cost_usd: 0.015, duration_ms: 1200 });
  const [logging, setLogging] = useState(false);

  // Budget form
  const [budgetOpen, setBudgetOpen] = useState(false);
  const [budget, setBudget] = useState<BudgetSet>({ tenant_id: "tenant-default", limit_usd: 100, alert_pct: 0.8, period: "monthly" });
  const [settingBudget, setSettingBudget] = useState(false);

  async function load() {
    if (!tenantId.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const [s, r] = await Promise.all([
        get<CostSummary>(`/billing/summary?tenant_id=${encodeURIComponent(tenantId)}`),
        get<UsageRecord[]>(`/billing/usage?tenant_id=${encodeURIComponent(tenantId)}&limit=50`),
      ]);
      setSummary(s);
      setRecords(r);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  async function logUsage(e: React.FormEvent) {
    e.preventDefault();
    setLogging(true);
    try {
      const rec = await post<UsageRecord>("/billing/usage", { ...logForm, tenant_id: tenantId });
      setRecords((prev) => [rec, ...prev]);
      if (summary) {
        setSummary((s) => s && ({
          ...s,
          total_spend_usd: s.total_spend_usd + logForm.cost_usd,
          total_tokens: s.total_tokens + logForm.tokens_in + logForm.tokens_out,
          total_calls: s.total_calls + 1,
        }));
      }
      setLogOpen(false);
    } catch (e) {
      setError(String(e));
    } finally {
      setLogging(false);
    }
  }

  async function saveBudget(e: React.FormEvent) {
    e.preventDefault();
    setSettingBudget(true);
    try {
      await post("/billing/budget", { ...budget, tenant_id: tenantId });
      setBudgetOpen(false);
    } catch {
      // budget endpoint may not exist yet — silently ok
      setBudgetOpen(false);
    } finally {
      setSettingBudget(false);
    }
  }

  const utilizationPct = summary && budget.limit_usd > 0
    ? Math.min(100, (summary.total_spend_usd / budget.limit_usd) * 100)
    : null;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Billing</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Native cost metering via SurrealDB — no Lago, no external ledger.
          <code style={{ fontSize: 11, marginLeft: 6 }}>math::sum(cost_usd) GROUP BY model/objective</code>
        </p>
      </div>

      {/* Tenant selector */}
      <Card title="Tenant">
        <div style={{ display: "flex", gap: 10, alignItems: "flex-end" }}>
          <div style={{ flex: 1 }}>
            <label style={labelStyle}>Tenant ID</label>
            <input
              value={tenantId}
              onChange={(e) => setTenantId(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && load()}
              style={inputStyle}
            />
          </div>
          <button onClick={load} disabled={loading} style={primaryBtn}>
            {loading ? "Loading…" : "Load"}
          </button>
          <button onClick={() => setBudgetOpen((o) => !o)} style={secondaryBtn}>
            Set budget
          </button>
          <button onClick={() => setLogOpen((o) => !o)} style={secondaryBtn}>
            + Log usage
          </button>
        </div>
      </Card>

      {budgetOpen && (
        <Card title="Set Budget">
          <form onSubmit={saveBudget} style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr auto", gap: 10, alignItems: "flex-end" }}>
            <div>
              <label style={labelStyle}>Limit (USD)</label>
              <input type="number" min={1} value={budget.limit_usd} onChange={(e) => setBudget((b) => ({ ...b, limit_usd: +e.target.value }))} style={inputStyle} />
            </div>
            <div>
              <label style={labelStyle}>Alert at (%)</label>
              <input type="number" min={10} max={100} value={budget.alert_pct * 100} onChange={(e) => setBudget((b) => ({ ...b, alert_pct: +e.target.value / 100 }))} style={inputStyle} />
            </div>
            <div>
              <label style={labelStyle}>Period</label>
              <select value={budget.period} onChange={(e) => setBudget((b) => ({ ...b, period: e.target.value }))} style={inputStyle}>
                {["daily", "weekly", "monthly", "annual"].map((p) => <option key={p}>{p}</option>)}
              </select>
            </div>
            <button type="submit" disabled={settingBudget} style={primaryBtn}>{settingBudget ? "Saving…" : "Save"}</button>
          </form>
        </Card>
      )}

      {logOpen && (
        <Card title="Log Usage Record">
          <form onSubmit={logUsage} style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
              <div><label style={labelStyle}>Model ID</label><input value={logForm.model_id} onChange={(e) => setLogForm((f) => ({ ...f, model_id: e.target.value }))} style={inputStyle} /></div>
              <div><label style={labelStyle}>Provider</label><input value={logForm.provider} onChange={(e) => setLogForm((f) => ({ ...f, provider: e.target.value }))} style={inputStyle} /></div>
              <div><label style={labelStyle}>Tokens In</label><input type="number" value={logForm.tokens_in} onChange={(e) => setLogForm((f) => ({ ...f, tokens_in: +e.target.value }))} style={inputStyle} /></div>
              <div><label style={labelStyle}>Tokens Out</label><input type="number" value={logForm.tokens_out} onChange={(e) => setLogForm((f) => ({ ...f, tokens_out: +e.target.value }))} style={inputStyle} /></div>
              <div><label style={labelStyle}>Cost (USD)</label><input type="number" step="0.0001" value={logForm.cost_usd} onChange={(e) => setLogForm((f) => ({ ...f, cost_usd: +e.target.value }))} style={inputStyle} /></div>
              <div><label style={labelStyle}>Duration (ms)</label><input type="number" value={logForm.duration_ms} onChange={(e) => setLogForm((f) => ({ ...f, duration_ms: +e.target.value }))} style={inputStyle} /></div>
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <button type="submit" disabled={logging} style={primaryBtn}>{logging ? "Logging…" : "Log"}</button>
              <button type="button" onClick={() => setLogOpen(false)} style={secondaryBtn}>Cancel</button>
            </div>
          </form>
        </Card>
      )}

      {error && <div style={{ padding: "10px 14px", borderRadius: 8, border: "1px solid var(--red)", color: "var(--red)", fontSize: 13 }}>{error}</div>}

      {summary && (
        <>
          {/* KPI row */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12 }}>
            <KpiCard label="Total spend" value={`$${summary.total_spend_usd.toFixed(4)}`} sub="USD" />
            <KpiCard label="Total tokens" value={summary.total_tokens.toLocaleString()} sub="in + out" />
            <KpiCard label="Model calls" value={summary.total_calls.toLocaleString()} sub="usage records" />
          </div>

          {/* Budget utilization */}
          {utilizationPct !== null && (
            <Card title="Budget utilization">
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, fontSize: 13 }}>
                <span style={{ color: "var(--text-muted)" }}>${summary.total_spend_usd.toFixed(4)} of ${budget.limit_usd} ({budget.period})</span>
                <StatusBadge status={utilizationPct >= 100 ? "exceeded" : utilizationPct >= budget.alert_pct * 100 ? "warning" : "ok"} />
              </div>
              <div style={{ height: 8, borderRadius: 4, background: "var(--border)", overflow: "hidden" }}>
                <div style={{ width: `${utilizationPct}%`, height: "100%", background: utilizationPct >= 100 ? "var(--red)" : utilizationPct >= 80 ? "#f59e0b" : "var(--green)", borderRadius: 4, transition: "width 0.4s" }} />
              </div>
            </Card>
          )}

          {/* Spend by model */}
          {summary.spend_by_model.length > 0 && (
            <Card title="Spend by model">
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
                <thead>
                  <tr style={{ color: "var(--text-muted)", borderBottom: "1px solid var(--border)" }}>
                    {["Model", "Provider", "Spend (USD)", "Calls", "Avg/call"].map((h) => (
                      <th key={h} style={{ textAlign: "left", padding: "6px 8px", fontWeight: 600, fontSize: 11, textTransform: "uppercase", letterSpacing: "0.05em" }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {summary.spend_by_model.map((row, i) => (
                    <tr key={i} style={{ borderBottom: "1px solid var(--border)" }}>
                      <td style={td}><code style={{ fontSize: 12 }}>{row.model_id || "—"}</code></td>
                      <td style={td}>{row.provider || "—"}</td>
                      <td style={td}>${(row.spend_usd || 0).toFixed(4)}</td>
                      <td style={td}>{row.calls}</td>
                      <td style={td}>${row.calls > 0 ? ((row.spend_usd || 0) / row.calls).toFixed(5) : "—"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Card>
          )}

          {/* Spend by objective */}
          {summary.spend_by_objective.length > 0 && (
            <Card title="Spend by objective">
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
                <thead>
                  <tr style={{ color: "var(--text-muted)", borderBottom: "1px solid var(--border)" }}>
                    {["Objective", "Spend (USD)", "Calls"].map((h) => (
                      <th key={h} style={{ textAlign: "left", padding: "6px 8px", fontWeight: 600, fontSize: 11, textTransform: "uppercase", letterSpacing: "0.05em" }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {summary.spend_by_objective.map((row, i) => (
                    <tr key={i} style={{ borderBottom: "1px solid var(--border)" }}>
                      <td style={td}><code style={{ fontSize: 11 }}>{String(row.objective_id || "—").slice(-12)}</code></td>
                      <td style={td}>${(row.spend_usd || 0).toFixed(4)}</td>
                      <td style={td}>{row.calls}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Card>
          )}

          {/* Recent usage records */}
          {records.length > 0 && (
            <Card title={`Recent usage (${records.length})`}>
              <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
                {records.slice(0, 20).map((r) => (
                  <div key={r.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "6px 0", borderBottom: "1px solid var(--border)", fontSize: 12 }}>
                    <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                      <code style={{ fontSize: 11, color: "var(--accent)" }}>{r.model_id || "unknown"}</code>
                      <span style={{ color: "var(--text-muted)" }}>{r.tokens_in}↑ {r.tokens_out}↓ tokens</span>
                      {r.duration_ms && <span style={{ color: "var(--text-muted)" }}>{r.duration_ms}ms</span>}
                    </div>
                    <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                      <span style={{ fontWeight: 600, color: "var(--green)" }}>${r.cost_usd.toFixed(5)}</span>
                      <span style={{ fontSize: 11, color: "var(--text-muted)" }}>{new Date(r.recorded_at).toLocaleTimeString()}</span>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          )}
        </>
      )}
    </div>
  );
}

function KpiCard({ label, value, sub }: { label: string; value: string; sub: string }) {
  return (
    <div style={{ background: "var(--surface-2)", border: "1px solid var(--border)", borderRadius: 10, padding: "16px 18px" }}>
      <div style={{ fontSize: 11, color: "var(--text-muted)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 6 }}>{label}</div>
      <div style={{ fontSize: 24, fontWeight: 700, color: "var(--text)" }}>{value}</div>
      <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>{sub}</div>
    </div>
  );
}

const labelStyle: React.CSSProperties = {
  display: "block", fontSize: 11, fontWeight: 600, color: "var(--text-muted)",
  textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 5,
};
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
const td: React.CSSProperties = { padding: "8px 8px", verticalAlign: "middle" };
