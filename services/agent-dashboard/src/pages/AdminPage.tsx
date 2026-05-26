import { useEffect, useState } from "react";

const BASE = "/api";

interface RateLimitConfig {
  id: string;
  config_id: string;
  tenant_id: string;
  agent_id?: string;
  scope: string;
  resource: string;
  limit: number;
  window: string;
  burst_limit?: number;
  active: boolean;
}

async function apiFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(`${BASE}${path}`, { headers: { "Content-Type": "application/json" }, ...opts });
  if (!r.ok) throw new Error(`${r.status}`);
  return r.json();
}

const SECTIONS = ["Rate Limits", "Budget", "Platform Info"] as const;
type Section = typeof SECTIONS[number];

export function AdminPage() {
  const [activeSection, setActiveSection] = useState<Section>("Rate Limits");
  const [tenantId, setTenantId] = useState("tenant-default");
  const [rateLimits, setRateLimits] = useState<RateLimitConfig[]>([]);
  const [loading, setLoading] = useState(false);
  const [health, setHealth] = useState<Record<string, unknown> | null>(null);

  // Rate limit form
  const [rlForm, setRlForm] = useState({ resource: "llm_calls", limit: "100", window: "1m", scope: "tenant", burst_limit: "" });
  const [showRlForm, setShowRlForm] = useState(false);

  // Budget form
  const [budgetForm, setBudgetForm] = useState({ limit_usd: "50", alert_pct: "0.8", period: "monthly" });
  const [budgetSaved, setBudgetSaved] = useState(false);

  const loadRateLimits = async () => {
    setLoading(true);
    try {
      const data = await apiFetch<RateLimitConfig[]>(`/rate-limits/configs?tenant_id=${encodeURIComponent(tenantId)}`);
      setRateLimits(data);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  const loadHealth = async () => {
    try {
      const data = await apiFetch<Record<string, unknown>>("/health");
      setHealth(data);
    } catch (e) { console.error(e); }
  };

  useEffect(() => { loadHealth(); }, []);
  useEffect(() => { if (activeSection === "Rate Limits") loadRateLimits(); }, [activeSection, tenantId]);

  const createRateLimit = async () => {
    try {
      await apiFetch("/rate-limits/configs", {
        method: "POST",
        body: JSON.stringify({
          tenant_id: tenantId,
          resource: rlForm.resource,
          limit: parseInt(rlForm.limit),
          window: rlForm.window,
          scope: rlForm.scope,
          burst_limit: rlForm.burst_limit ? parseInt(rlForm.burst_limit) : undefined,
        }),
      });
      setShowRlForm(false);
      loadRateLimits();
    } catch (e) { alert(String(e)); }
  };

  const deleteRateLimit = async (cfg: RateLimitConfig) => {
    try {
      await apiFetch(`/rate-limits/configs/${cfg.config_id}`, { method: "DELETE" });
      loadRateLimits();
    } catch (e) { alert(String(e)); }
  };

  const saveBudget = async () => {
    try {
      // Budget is stored via billing router
      await apiFetch("/billing/budget", {
        method: "POST",
        body: JSON.stringify({
          tenant_id: tenantId,
          limit_usd: parseFloat(budgetForm.limit_usd),
          alert_pct: parseFloat(budgetForm.alert_pct),
          period: budgetForm.period,
        }),
      });
      setBudgetSaved(true);
      setTimeout(() => setBudgetSaved(false), 2000);
    } catch (e) { alert(String(e)); }
  };

  const inp = (extra?: React.CSSProperties): React.CSSProperties => ({
    padding: "7px 10px", borderRadius: 6, border: "1px solid var(--border)",
    background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
    width: "100%", boxSizing: "border-box" as const, ...extra,
  });

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>Admin</h1>
        <p style={{ margin: "4px 0 0", color: "var(--text-muted)", fontSize: 13 }}>
          Platform configuration — rate limits, budgets, platform info
        </p>
      </div>

      {/* Tenant selector */}
      <div style={{ display: "flex", gap: 8, marginBottom: 20, alignItems: "center" }}>
        <span style={{ fontSize: 13, color: "var(--text-muted)" }}>Tenant</span>
        <input value={tenantId} onChange={(e) => setTenantId(e.target.value)}
          style={{ padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", fontSize: 13, width: 220 }}
        />
      </div>

      {/* Section tabs */}
      <div style={{ display: "flex", gap: 2, marginBottom: 20, borderBottom: "1px solid var(--border)" }}>
        {SECTIONS.map((s) => (
          <button key={s} onClick={() => setActiveSection(s)}
            style={{
              padding: "8px 18px", border: "none", cursor: "pointer", fontSize: 13, background: "transparent",
              fontWeight: activeSection === s ? 700 : 400,
              color: activeSection === s ? "var(--text)" : "var(--text-muted)",
              borderBottom: activeSection === s ? "2px solid var(--accent)" : "2px solid transparent",
            }}
          >{s}</button>
        ))}
      </div>

      {/* ── Rate Limits ── */}
      {activeSection === "Rate Limits" && (
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <div style={{ fontWeight: 600 }}>Rate Limit Configs</div>
            <button onClick={() => setShowRlForm((v) => !v)} style={{ padding: "6px 14px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13 }}>
              + Add Config
            </button>
          </div>

          {showRlForm && (
            <div style={{ background: "var(--surface-2)", borderRadius: 8, padding: 16, marginBottom: 14, border: "1px solid var(--border)" }}>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 10 }}>
                <div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Resource</div>
                  <select value={rlForm.resource} onChange={(e) => setRlForm({ ...rlForm, resource: e.target.value })} style={inp()}>
                    {["llm_calls","tokens","objectives","artifacts","memory_writes","api_requests"].map((r) => <option key={r} value={r}>{r}</option>)}
                  </select>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Limit</div>
                  <input type="number" value={rlForm.limit} onChange={(e) => setRlForm({ ...rlForm, limit: e.target.value })} style={inp()} />
                </div>
                <div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Window</div>
                  <select value={rlForm.window} onChange={(e) => setRlForm({ ...rlForm, window: e.target.value })} style={inp()}>
                    {["1m","5m","15m","1h","24h","1month"].map((w) => <option key={w} value={w}>{w}</option>)}
                  </select>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Scope</div>
                  <select value={rlForm.scope} onChange={(e) => setRlForm({ ...rlForm, scope: e.target.value })} style={inp()}>
                    {["tenant","agent","model","endpoint"].map((s) => <option key={s} value={s}>{s}</option>)}
                  </select>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Burst limit (opt)</div>
                  <input type="number" value={rlForm.burst_limit} onChange={(e) => setRlForm({ ...rlForm, burst_limit: e.target.value })} placeholder="e.g. 150" style={inp()} />
                </div>
              </div>
              <div style={{ display: "flex", gap: 8 }}>
                <button onClick={createRateLimit} style={{ padding: "7px 16px", borderRadius: 6, border: "none", background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13 }}>Save</button>
                <button onClick={() => setShowRlForm(false)} style={{ padding: "7px 12px", borderRadius: 6, border: "1px solid var(--border)", background: "transparent", color: "var(--text)", cursor: "pointer", fontSize: 13 }}>Cancel</button>
              </div>
            </div>
          )}

          {loading && <div style={{ color: "var(--text-muted)", fontSize: 13 }}>Loading…</div>}
          {!loading && rateLimits.length === 0 && (
            <div style={{ background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: 20, textAlign: "center", color: "var(--text-muted)", fontSize: 13 }}>
              No rate limit configs for this tenant.
            </div>
          )}
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
            {rateLimits.length > 0 && (
              <thead>
                <tr style={{ color: "var(--text-muted)", textAlign: "left" }}>
                  {["Resource", "Scope", "Limit", "Window", "Burst", "Active", ""].map((h) => (
                    <th key={h} style={{ padding: "6px 10px", fontWeight: 500, borderBottom: "1px solid var(--border)" }}>{h}</th>
                  ))}
                </tr>
              </thead>
            )}
            <tbody>
              {rateLimits.map((cfg) => (
                <tr key={cfg.id} style={{ borderBottom: "1px solid var(--border)" }}>
                  <td style={{ padding: "8px 10px", fontWeight: 600 }}>{cfg.resource}</td>
                  <td style={{ padding: "8px 10px", color: "var(--text-muted)" }}>{cfg.scope}</td>
                  <td style={{ padding: "8px 10px" }}>{cfg.limit.toLocaleString()}</td>
                  <td style={{ padding: "8px 10px", color: "var(--text-muted)" }}>{cfg.window}</td>
                  <td style={{ padding: "8px 10px", color: "var(--text-muted)" }}>{cfg.burst_limit ?? "—"}</td>
                  <td style={{ padding: "8px 10px" }}>
                    <span style={{ color: cfg.active ? "var(--success)" : "var(--error)", fontWeight: 600 }}>{cfg.active ? "yes" : "no"}</span>
                  </td>
                  <td style={{ padding: "8px 10px" }}>
                    <button onClick={() => deleteRateLimit(cfg)} style={{ padding: "3px 8px", fontSize: 11, borderRadius: 4, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", cursor: "pointer" }}>
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Budget ── */}
      {activeSection === "Budget" && (
        <div style={{ maxWidth: 440 }}>
          <div style={{ fontWeight: 600, marginBottom: 14 }}>Monthly Budget — {tenantId}</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div>
              <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>Monthly limit (USD)</div>
              <input type="number" value={budgetForm.limit_usd} onChange={(e) => setBudgetForm({ ...budgetForm, limit_usd: e.target.value })} style={inp({ width: 200 })} />
            </div>
            <div>
              <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>Alert threshold ({(parseFloat(budgetForm.alert_pct) * 100).toFixed(0)}%)</div>
              <input type="range" min={0.1} max={0.99} step={0.05}
                value={budgetForm.alert_pct}
                onChange={(e) => setBudgetForm({ ...budgetForm, alert_pct: e.target.value })}
                style={{ width: 200 }}
              />
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                Notification fires at ${(parseFloat(budgetForm.limit_usd) * parseFloat(budgetForm.alert_pct)).toFixed(2)} spent
              </div>
            </div>
            <button onClick={saveBudget} style={{
              alignSelf: "flex-start", padding: "8px 20px", borderRadius: 6, border: "none",
              background: budgetSaved ? "var(--success)" : "var(--accent)", color: "#fff",
              cursor: "pointer", fontWeight: 600, fontSize: 13, transition: "background 0.2s",
            }}>
              {budgetSaved ? "Saved ✓" : "Save Budget"}
            </button>
          </div>
        </div>
      )}

      {/* ── Platform Info ── */}
      {activeSection === "Platform Info" && (
        <div>
          <div style={{ fontWeight: 600, marginBottom: 14 }}>Platform Status</div>
          {health ? (
            <div style={{ display: "flex", flexDirection: "column", gap: 8, maxWidth: 500 }}>
              {Object.entries(health).map(([k, v]) => (
                <div key={k} style={{ display: "flex", justifyContent: "space-between", padding: "8px 14px", background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8 }}>
                  <span style={{ color: "var(--text-muted)", fontSize: 13 }}>{k}</span>
                  <span style={{ fontWeight: 600, fontSize: 13, color: String(v) === "ok" ? "var(--success)" : "var(--text)" }}>{String(v)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div style={{ color: "var(--text-muted)", fontSize: 13 }}>Loading health…</div>
          )}

          <div style={{ fontWeight: 600, marginBottom: 10, marginTop: 24 }}>Schema DEFINE PARAMs</div>
          <div style={{ background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: "12px 16px", fontSize: 12, fontFamily: "monospace" }}>
            {[
              ["$MIN_TRUST_SCORE", "0.7", "CLEAR gate threshold"],
              ["$MAX_COST_PER_OBJECTIVE", "10.0", "Hard budget cap per run"],
              ["$MAX_MEMORY_AGE", "30d", "Memory TTL before archive"],
              ["$REQUIRED_CAPABILITIES", "8 flags", "Agent registration gate"],
            ].map(([param, value, desc]) => (
              <div key={param} style={{ display: "flex", gap: 16, marginBottom: 8, alignItems: "center" }}>
                <span style={{ color: "var(--accent)", minWidth: 200 }}>{param}</span>
                <span style={{ color: "var(--success)", minWidth: 60 }}>{value}</span>
                <span style={{ color: "var(--text-muted)", fontSize: 11 }}>{desc}</span>
              </div>
            ))}
          </div>

          <div style={{ fontWeight: 600, marginBottom: 10, marginTop: 24 }}>Router Inventory</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
            {[
              "health","objectives","agents","memory","tasks","artifacts","trust","billing",
              "blueprints","skills","workflow","traces","sessions","knowledge","deployments",
              "observability","credentials","rate-limits","alerts",
            ].map((r) => (
              <span key={r} style={{ fontSize: 11, padding: "3px 9px", borderRadius: 6, background: "var(--accent)22", color: "var(--accent)", fontFamily: "monospace" }}>
                /{r}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
