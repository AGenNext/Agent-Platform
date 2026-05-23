import { useEffect, useState } from "react";

const BASE = "/api";

interface Deployment {
  id: string;
  deployment_id: string;
  agent_id: string;
  tenant_id: string;
  version: string;
  strategy: string;
  traffic_pct: number;
  previous_version?: string;
  status: string;
  health_checks_passed: number;
  health_checks_required: number;
  auto_rollback: boolean;
  deployed_by?: string;
  started_at: string;
  completed_at?: string;
  notes?: string;
}

interface AgentVersion {
  id: string;
  version: string;
  version_num: number;
  change_type: string;
  changelog?: string;
  created_at: string;
  created_by?: string;
  approved_by?: string;
}

const STATUS_COLORS: Record<string, string> = {
  pending: "#f59e0b",
  in_progress: "var(--accent)",
  healthy: "var(--success)",
  degraded: "#f97316",
  rolled_back: "var(--text-muted)",
  failed: "var(--error)",
};

const STRATEGY_ICONS: Record<string, string> = {
  rolling: "↻",
  canary: "⁓",
  blue_green: "⇄",
  recreate: "⊕",
  shadow: "◎",
};

async function apiFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...opts,
  });
  if (!r.ok) throw new Error(`${r.status} ${r.statusText}`);
  return r.json();
}

export function DeploymentsPage() {
  const [deployments, setDeployments] = useState<Deployment[]>([]);
  const [versions, setVersions] = useState<AgentVersion[]>([]);
  const [selected, setSelected] = useState<Deployment | null>(null);
  const [loading, setLoading] = useState(false);
  const [filterTenant, setFilterTenant] = useState("");
  const [filterAgent, setFilterAgent] = useState("");
  const [filterStatus, setFilterStatus] = useState("");

  // New deployment form
  const [showNew, setShowNew] = useState(false);
  const [newAgentId, setNewAgentId] = useState("");
  const [newTenantId, setNewTenantId] = useState("tenant-default");
  const [newVersion, setNewVersion] = useState("1.0.0");
  const [newStrategy, setNewStrategy] = useState("rolling");
  const [newTrafficPct, setNewTrafficPct] = useState(100);
  const [newNotes, setNewNotes] = useState("");

  const loadDeployments = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filterTenant) params.set("tenant_id", filterTenant);
      if (filterAgent) params.set("agent_id", filterAgent);
      if (filterStatus) params.set("status", filterStatus);
      const data = await apiFetch<Deployment[]>(`/deployments/?${params}`);
      setDeployments(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const loadVersions = async (agentId: string) => {
    try {
      const data = await apiFetch<AgentVersion[]>(`/deployments/agents/${agentId}/versions`);
      setVersions(data);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => { loadDeployments(); }, []);
  useEffect(() => {
    if (selected) loadVersions(selected.agent_id);
  }, [selected]);

  const createDeployment = async () => {
    if (!newAgentId || !newVersion) return;
    try {
      await apiFetch("/deployments/", {
        method: "POST",
        body: JSON.stringify({
          agent_id: newAgentId,
          tenant_id: newTenantId,
          version: newVersion,
          strategy: newStrategy,
          traffic_pct: newTrafficPct,
          notes: newNotes || undefined,
        }),
      });
      setShowNew(false);
      setNewAgentId("");
      setNewNotes("");
      loadDeployments();
    } catch (e) {
      alert(String(e));
    }
  };

  const updateStatus = async (dep: Deployment, status: string, healthCheck = false) => {
    try {
      await apiFetch(
        `/deployments/${dep.deployment_id}/status?status=${status}&health_check=${healthCheck}`,
        { method: "PATCH" },
      );
      loadDeployments();
      if (selected?.deployment_id === dep.deployment_id) {
        setSelected({ ...dep, status });
      }
    } catch (e) {
      alert(String(e));
    }
  };

  const fmtTime = (iso: string) =>
    new Date(iso).toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });

  const duration = (dep: Deployment) => {
    const end = dep.completed_at ? new Date(dep.completed_at) : new Date();
    const ms = end.getTime() - new Date(dep.started_at).getTime();
    const m = Math.floor(ms / 60000);
    return m < 1 ? "<1m" : `${m}m`;
  };

  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>Deployments</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-muted)", fontSize: 13 }}>
            Agent version management — rollouts, canary, auto-rollback
          </p>
        </div>
        <button
          onClick={() => setShowNew(true)}
          style={{
            padding: "8px 16px", borderRadius: 6, border: "none",
            background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13,
          }}
        >
          Deploy
        </button>
      </div>

      {/* Filters */}
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        {[
          { ph: "Tenant ID", val: filterTenant, set: setFilterTenant },
          { ph: "Agent ID", val: filterAgent, set: setFilterAgent },
        ].map(({ ph, val, set }) => (
          <input key={ph} placeholder={ph} value={val} onChange={(e) => set(e.target.value)}
            style={{
              padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)",
              background: "var(--surface-2)", color: "var(--text)", fontSize: 13, flex: 1,
            }}
          />
        ))}
        <select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}
          style={{
            padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)",
            background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
          }}
        >
          <option value="">All statuses</option>
          {["pending", "in_progress", "healthy", "degraded", "rolled_back", "failed"].map((s) => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
        <button onClick={loadDeployments} style={{
          padding: "6px 14px", borderRadius: 6, border: "1px solid var(--border)",
          background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13,
        }}>Load</button>
      </div>

      {/* New deployment modal */}
      {showNew && (
        <div style={{
          position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", display: "flex",
          alignItems: "center", justifyContent: "center", zIndex: 100,
        }}>
          <div style={{
            background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 10, padding: 24, width: 440,
          }}>
            <h3 style={{ margin: "0 0 16px" }}>New Deployment</h3>
            {[
              { label: "Agent ID *", val: newAgentId, set: setNewAgentId, ph: "agent-abc123" },
              { label: "Tenant ID", val: newTenantId, set: setNewTenantId, ph: "tenant-default" },
              { label: "Version *", val: newVersion, set: setNewVersion, ph: "1.0.0" },
              { label: "Notes", val: newNotes, set: setNewNotes, ph: "Updated model config" },
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
            <div style={{ display: "flex", gap: 12, marginBottom: 12 }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>Strategy</div>
                <select value={newStrategy} onChange={(e) => setNewStrategy(e.target.value)}
                  style={{
                    width: "100%", padding: "8px 10px", borderRadius: 6,
                    border: "1px solid var(--border)", background: "var(--surface-2)",
                    color: "var(--text)", fontSize: 13,
                  }}
                >
                  {["rolling", "canary", "blue_green", "recreate", "shadow"].map((s) => (
                    <option key={s} value={s}>{STRATEGY_ICONS[s]} {s}</option>
                  ))}
                </select>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 4 }}>
                  Traffic % ({newTrafficPct}%)
                </div>
                <input type="range" min={0} max={100} step={10}
                  value={newTrafficPct}
                  onChange={(e) => setNewTrafficPct(Number(e.target.value))}
                  style={{ width: "100%", marginTop: 6 }}
                />
              </div>
            </div>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button onClick={() => setShowNew(false)} style={{
                padding: "8px 14px", borderRadius: 6, border: "1px solid var(--border)",
                background: "transparent", color: "var(--text)", cursor: "pointer",
              }}>Cancel</button>
              <button onClick={createDeployment} disabled={!newAgentId || !newVersion} style={{
                padding: "8px 16px", borderRadius: 6, border: "none",
                background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600,
              }}>Deploy</button>
            </div>
          </div>
        </div>
      )}

      {loading && <div style={{ color: "var(--text-muted)", fontSize: 13, marginBottom: 12 }}>Loading…</div>}

      {/* Deployment list */}
      <div style={{ display: "flex", gap: 16 }}>
        <div style={{ flex: 1 }}>
          {deployments.length === 0 && !loading && (
            <div style={{
              background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8,
              padding: 24, textAlign: "center", color: "var(--text-muted)", fontSize: 13,
            }}>
              No deployments found. Click Deploy to start a new rollout.
            </div>
          )}
          {deployments.map((dep) => (
            <div
              key={dep.id}
              onClick={() => setSelected(dep)}
              style={{
                background: "var(--surface)", border: `1px solid ${selected?.deployment_id === dep.deployment_id ? "var(--accent)" : "var(--border)"}`,
                borderRadius: 8, padding: "14px 16px", marginBottom: 10, cursor: "pointer",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                    <span style={{ fontWeight: 700, fontSize: 14 }}>{dep.agent_id}</span>
                    <span style={{ fontFamily: "monospace", fontSize: 12, color: "var(--accent)" }}>
                      v{dep.version}
                    </span>
                    <span style={{ fontSize: 12, color: "var(--text-muted)" }}>
                      {STRATEGY_ICONS[dep.strategy]} {dep.strategy}
                    </span>
                    {dep.traffic_pct < 100 && (
                      <span style={{ fontSize: 11, color: "#f59e0b" }}>{dep.traffic_pct}% traffic</span>
                    )}
                  </div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 4 }}>
                    {dep.tenant_id} · {fmtTime(dep.started_at)} · {duration(dep)}
                    {dep.deployed_by && ` · by ${dep.deployed_by}`}
                  </div>
                  {dep.notes && (
                    <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 4 }}>{dep.notes}</div>
                  )}
                </div>
                <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>
                  <span style={{
                    fontSize: 11, padding: "3px 8px", borderRadius: 10, fontWeight: 600,
                    background: STATUS_COLORS[dep.status] + "22",
                    color: STATUS_COLORS[dep.status],
                  }}>
                    {dep.status}
                  </span>
                  {dep.status === "pending" || dep.status === "in_progress" ? (
                    <div style={{ display: "flex", gap: 4 }}>
                      <button onClick={(e) => { e.stopPropagation(); updateStatus(dep, "in_progress", true); }}
                        style={{
                          padding: "3px 8px", fontSize: 11, borderRadius: 4,
                          border: "1px solid var(--border)", background: "var(--surface-2)",
                          color: "var(--text)", cursor: "pointer",
                        }}
                      >Health check</button>
                      <button onClick={(e) => { e.stopPropagation(); updateStatus(dep, "healthy"); }}
                        style={{
                          padding: "3px 8px", fontSize: 11, borderRadius: 4, border: "none",
                          background: "var(--success)", color: "#fff", cursor: "pointer",
                        }}
                      >Mark Healthy</button>
                      <button onClick={(e) => { e.stopPropagation(); updateStatus(dep, "failed"); }}
                        style={{
                          padding: "3px 8px", fontSize: 11, borderRadius: 4, border: "none",
                          background: "var(--error)", color: "#fff", cursor: "pointer",
                        }}
                      >Fail</button>
                    </div>
                  ) : null}
                </div>
              </div>

              {/* Health progress bar */}
              {(dep.status === "in_progress" || dep.status === "pending") && dep.health_checks_required > 0 && (
                <div style={{ marginTop: 8 }}>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>
                    Health gates: {dep.health_checks_passed}/{dep.health_checks_required}
                  </div>
                  <div style={{ height: 4, background: "var(--surface-2)", borderRadius: 2, overflow: "hidden" }}>
                    <div style={{
                      height: "100%",
                      width: `${(dep.health_checks_passed / dep.health_checks_required) * 100}%`,
                      background: "var(--success)", transition: "width 0.3s",
                    }} />
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Version history panel */}
        {selected && (
          <div style={{
            width: 280, flexShrink: 0, background: "var(--surface)",
            border: "1px solid var(--border)", borderRadius: 8, padding: 14, alignSelf: "flex-start",
          }}>
            <div style={{ fontWeight: 600, marginBottom: 12 }}>
              Version history — {selected.agent_id}
            </div>
            {versions.length === 0 ? (
              <div style={{ fontSize: 12, color: "var(--text-muted)" }}>No versions recorded.</div>
            ) : (
              versions.map((v) => (
                <div key={v.id} style={{
                  padding: "8px 0", borderBottom: "1px solid var(--border)",
                }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{ fontFamily: "monospace", fontSize: 12, fontWeight: 600, color: "var(--accent)" }}>
                      v{v.version}
                    </span>
                    <span style={{ fontSize: 10, color: "var(--text-muted)" }}>
                      {new Date(v.created_at).toLocaleDateString()}
                    </span>
                  </div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                    {v.change_type}
                    {v.approved_by && ` · approved by ${v.approved_by}`}
                  </div>
                  {v.changelog && (
                    <div style={{ fontSize: 11, color: "var(--text)", marginTop: 3 }}>{v.changelog}</div>
                  )}
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}
