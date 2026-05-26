import { useEffect, useState } from "react";

const BASE = "/api";

interface AlertRule {
  id: string;
  rule_id: string;
  tenant_id: string;
  name: string;
  description?: string;
  metric_name: string;
  condition: string;
  threshold: number;
  window: string;
  severity: string;
  notification_channels: string[];
  cooldown: string;
  active: boolean;
  fire_count: number;
}

interface AlertInstance {
  id: string;
  rule_id: string | { rule_id?: string; name?: string };
  severity: string;
  metric_value: number;
  threshold: number;
  status: string;
  message?: string;
  fired_at: string;
  resolved_at?: string;
  resolved_by?: string;
}

const SEV_COLORS: Record<string, string> = {
  critical: "#ef4444",
  error: "#f97316",
  warning: "#f59e0b",
  info: "var(--accent)",
};

const COND_LABELS: Record<string, string> = {
  gt: ">", gte: "≥", lt: "<", lte: "≤", eq: "=",
};

async function apiFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(`${BASE}${path}`, { headers: { "Content-Type": "application/json" }, ...opts });
  if (!r.ok) throw new Error(`${r.status}`);
  return r.json();
}

export function AlertRulesPage() {
  const [rules, setRules] = useState<AlertRule[]>([]);
  const [instances, setInstances] = useState<AlertInstance[]>([]);
  const [loading, setLoading] = useState(false);
  const [evaluating, setEvaluating] = useState(false);
  const [filterTenant, setFilterTenant] = useState("tenant-default");
  const [showNew, setShowNew] = useState(false);
  const [editRule, setEditRule] = useState<AlertRule | null>(null);
  const [activeTab, setActiveTab] = useState<"rules" | "instances">("rules");

  const [form, setForm] = useState({
    name: "", metric_name: "tokens_out", condition: "gt",
    threshold: "1000", window: "5m", severity: "warning",
    cooldown: "15m", description: "", tenant_id: "tenant-default",
  });

  const loadRules = async () => {
    setLoading(true);
    try {
      const params = filterTenant ? `?tenant_id=${encodeURIComponent(filterTenant)}` : "";
      const [r, inst] = await Promise.all([
        apiFetch<AlertRule[]>(`/alerts/rules${params}`),
        apiFetch<AlertInstance[]>(`/alerts/instances${params}&limit=50`),
      ]);
      setRules(r);
      setInstances(inst);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { loadRules(); }, []);

  const createRule = async () => {
    if (!form.name || !form.metric_name) return;
    try {
      await apiFetch("/alerts/rules", {
        method: "POST",
        body: JSON.stringify({ ...form, threshold: parseFloat(form.threshold), tenant_id: filterTenant || form.tenant_id }),
      });
      setShowNew(false);
      setForm({ name: "", metric_name: "tokens_out", condition: "gt", threshold: "1000", window: "5m", severity: "warning", cooldown: "15m", description: "", tenant_id: "tenant-default" });
      loadRules();
    } catch (e) { alert(String(e)); }
  };

  const updateRule = async (rule: AlertRule, patch: Partial<AlertRule>) => {
    try {
      await apiFetch(`/alerts/rules/${rule.rule_id}`, {
        method: "PATCH",
        body: JSON.stringify(patch),
      });
      loadRules();
    } catch (e) { alert(String(e)); }
  };

  const deleteRule = async (rule: AlertRule) => {
    if (!confirm(`Delete rule "${rule.name}"?`)) return;
    try {
      await apiFetch(`/alerts/rules/${rule.rule_id}`, { method: "DELETE" });
      loadRules();
    } catch (e) { alert(String(e)); }
  };

  const resolveInstance = async (inst: AlertInstance) => {
    try {
      await apiFetch(`/alerts/instances/${inst.id}/resolve`, { method: "POST" });
      loadRules();
    } catch (e) { alert(String(e)); }
  };

  const evaluate = async () => {
    if (!filterTenant) return alert("Set a Tenant ID first");
    setEvaluating(true);
    try {
      const res = await apiFetch<{ rules_evaluated: number; alerts_fired: number }>(`/alerts/evaluate?tenant_id=${encodeURIComponent(filterTenant)}`, { method: "POST" });
      alert(`Evaluated ${res.rules_evaluated} rules — ${res.alerts_fired} alerts fired`);
      loadRules();
    } catch (e) { alert(String(e)); }
    finally { setEvaluating(false); }
  };

  const fmt = (iso: string) => new Date(iso).toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });

  const firing = instances.filter((i) => i.status === "firing");

  const inp = (extra?: React.CSSProperties): React.CSSProperties => ({
    padding: "7px 10px", borderRadius: 6, border: "1px solid var(--border)",
    background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
    width: "100%", boxSizing: "border-box" as const, ...extra,
  });

  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>Alert Rules</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-muted)", fontSize: 13 }}>
            Metric threshold alerts with auto-notification via DEFINE EVENT
          </p>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <button onClick={evaluate} disabled={evaluating} style={{ padding: "8px 14px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13 }}>
            {evaluating ? "Evaluating…" : "Evaluate Now"}
          </button>
          <button onClick={() => setShowNew(true)} style={{ padding: "8px 16px", borderRadius: 6, border: "none", background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13 }}>
            + New Rule
          </button>
        </div>
      </div>

      {/* Stats + filter */}
      <div style={{ display: "flex", gap: 12, marginBottom: 16, alignItems: "center" }}>
        <input placeholder="Tenant ID" value={filterTenant} onChange={(e) => setFilterTenant(e.target.value)}
          style={{ padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", fontSize: 13, width: 200 }}
        />
        <button onClick={loadRules} style={{ padding: "6px 14px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13 }}>
          {loading ? "…" : "Load"}
        </button>
        {firing.length > 0 && (
          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6, padding: "5px 12px", borderRadius: 8, background: "#ef444422", border: "1px solid #ef444444" }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#ef4444", animation: "pulse 1s infinite" }} />
            <span style={{ color: "#ef4444", fontWeight: 700, fontSize: 13 }}>{firing.length} firing</span>
          </div>
        )}
      </div>

      {/* Tabs */}
      <div style={{ display: "flex", gap: 2, marginBottom: 16, borderBottom: "1px solid var(--border)" }}>
        {(["rules", "instances"] as const).map((tab) => (
          <button key={tab} onClick={() => setActiveTab(tab)}
            style={{
              padding: "8px 16px", border: "none", cursor: "pointer", fontSize: 13,
              background: "transparent", fontWeight: activeTab === tab ? 700 : 400,
              color: activeTab === tab ? "var(--text)" : "var(--text-muted)",
              borderBottom: activeTab === tab ? "2px solid var(--accent)" : "2px solid transparent",
            }}
          >
            {tab === "rules" ? `Rules (${rules.length})` : `Instances (${instances.length})`}
          </button>
        ))}
      </div>

      {/* New rule modal */}
      {showNew && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100 }}>
          <div style={{ background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 10, padding: 24, width: 480 }}>
            <h3 style={{ margin: "0 0 16px" }}>New Alert Rule</h3>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 10 }}>
              {[
                { label: "Rule name *", key: "name", ph: "High token spend" },
                { label: "Metric name *", key: "metric_name", ph: "tokens_out" },
              ].map(({ label, key, ph }) => (
                <div key={key}>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>{label}</div>
                  <input value={(form as any)[key]} onChange={(e) => setForm({ ...form, [key]: e.target.value })} placeholder={ph} style={inp()} />
                </div>
              ))}
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10, marginBottom: 10 }}>
              <div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Condition</div>
                <select value={form.condition} onChange={(e) => setForm({ ...form, condition: e.target.value })} style={inp()}>
                  {Object.entries(COND_LABELS).map(([k, v]) => <option key={k} value={k}>{v} ({k})</option>)}
                </select>
              </div>
              <div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Threshold</div>
                <input type="number" value={form.threshold} onChange={(e) => setForm({ ...form, threshold: e.target.value })} style={inp()} />
              </div>
              <div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Window</div>
                <select value={form.window} onChange={(e) => setForm({ ...form, window: e.target.value })} style={inp()}>
                  {["1m","5m","15m","30m","1h","6h","24h"].map((w) => <option key={w} value={w}>{w}</option>)}
                </select>
              </div>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 12 }}>
              <div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Severity</div>
                <select value={form.severity} onChange={(e) => setForm({ ...form, severity: e.target.value })} style={inp()}>
                  {["info","warning","error","critical"].map((s) => <option key={s} value={s}>{s}</option>)}
                </select>
              </div>
              <div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Cooldown</div>
                <select value={form.cooldown} onChange={(e) => setForm({ ...form, cooldown: e.target.value })} style={inp()}>
                  {["1m","5m","15m","30m","1h","6h"].map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
            </div>
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Description (optional)</div>
              <input value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} placeholder="Alert when..." style={inp()} />
            </div>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button onClick={() => setShowNew(false)} style={{ padding: "8px 14px", borderRadius: 6, border: "1px solid var(--border)", background: "transparent", color: "var(--text)", cursor: "pointer" }}>Cancel</button>
              <button onClick={createRule} disabled={!form.name || !form.metric_name} style={{ padding: "8px 16px", borderRadius: 6, border: "none", background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600 }}>Create</button>
            </div>
          </div>
        </div>
      )}

      {/* Rules tab */}
      {activeTab === "rules" && (
        <div>
          {loading && <div style={{ color: "var(--text-muted)", fontSize: 13 }}>Loading…</div>}
          {!loading && rules.length === 0 && (
            <div style={{ background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: 24, textAlign: "center", color: "var(--text-muted)", fontSize: 13 }}>
              No alert rules yet. Create one above.
            </div>
          )}
          {rules.map((rule) => (
            <div key={rule.id} style={{
              background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8,
              padding: "14px 16px", marginBottom: 10, opacity: rule.active ? 1 : 0.6,
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
                    <span style={{ fontWeight: 700, fontSize: 14 }}>{rule.name}</span>
                    <span style={{ fontSize: 11, padding: "2px 7px", borderRadius: 10, fontWeight: 600, background: (SEV_COLORS[rule.severity] ?? "var(--text-muted)") + "22", color: SEV_COLORS[rule.severity] ?? "var(--text-muted)" }}>
                      {rule.severity}
                    </span>
                    {!rule.active && <span style={{ fontSize: 10, color: "var(--error)", fontWeight: 700 }}>INACTIVE</span>}
                    {rule.fire_count > 0 && <span style={{ fontSize: 11, color: "var(--text-muted)" }}>fired {rule.fire_count}×</span>}
                  </div>
                  <div style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 4, fontFamily: "monospace" }}>
                    {rule.metric_name} {COND_LABELS[rule.condition]} {rule.threshold} · window: {rule.window} · cooldown: {rule.cooldown}
                  </div>
                  {rule.description && <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 3 }}>{rule.description}</div>}
                </div>
                <div style={{ display: "flex", gap: 6, flexShrink: 0 }}>
                  <button onClick={() => updateRule(rule, { active: !rule.active })} style={{
                    padding: "4px 10px", fontSize: 12, borderRadius: 6, border: "none", cursor: "pointer", fontWeight: 600,
                    background: rule.active ? "var(--error)22" : "var(--success)22",
                    color: rule.active ? "var(--error)" : "var(--success)",
                  }}>
                    {rule.active ? "Disable" : "Enable"}
                  </button>
                  <button onClick={() => deleteRule(rule)} style={{ padding: "4px 10px", fontSize: 12, borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", cursor: "pointer" }}>
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Instances tab */}
      {activeTab === "instances" && (
        <div>
          {instances.length === 0 && !loading && (
            <div style={{ background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: 24, textAlign: "center", color: "var(--text-muted)", fontSize: 13 }}>
              No alert instances. Click "Evaluate Now" to check current metric values.
            </div>
          )}
          {instances.map((inst) => (
            <div key={inst.id} style={{
              background: "var(--surface)", border: `1px solid ${inst.status === "firing" ? (SEV_COLORS[inst.severity] ?? "var(--border)") + "66" : "var(--border)"}`,
              borderRadius: 8, padding: "12px 16px", marginBottom: 8,
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                    <span style={{ fontSize: 11, padding: "2px 7px", borderRadius: 10, fontWeight: 600, background: (SEV_COLORS[inst.severity] ?? "var(--text-muted)") + "22", color: SEV_COLORS[inst.severity] ?? "var(--text-muted)" }}>
                      {inst.severity}
                    </span>
                    <span style={{ fontSize: 11, padding: "2px 7px", borderRadius: 10, fontWeight: 600, background: inst.status === "firing" ? "#ef444422" : "var(--success)22", color: inst.status === "firing" ? "#ef4444" : "var(--success)" }}>
                      {inst.status}
                    </span>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{inst.message ?? `value: ${inst.metric_value}`}</span>
                  </div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 4 }}>
                    Fired: {fmt(inst.fired_at)}
                    {inst.resolved_at && ` · Resolved: ${fmt(inst.resolved_at)}`}
                    {inst.resolved_by && ` by ${inst.resolved_by}`}
                  </div>
                </div>
                {inst.status === "firing" && (
                  <button onClick={() => resolveInstance(inst)} style={{ padding: "5px 12px", fontSize: 12, borderRadius: 6, border: "none", background: "var(--success)", color: "#fff", cursor: "pointer", fontWeight: 600 }}>
                    Resolve
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
