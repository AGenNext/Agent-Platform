import { useEffect, useState } from "react";

const BASE = "/api";

interface Credential {
  id: string;
  cred_id: string;
  tenant_id: string;
  agent_id?: string;
  name: string;
  provider: string;
  credential_type: string;
  description?: string;
  scopes: string[];
  active: boolean;
  last_used_at?: string;
  expires_at?: string;
  created_at: string;
}

const PROVIDER_COLORS: Record<string, string> = {
  anthropic: "#d97706",
  openai: "#10b981",
  stripe: "#6366f1",
  shopify: "#22c55e",
  github: "#8b5cf6",
  slack: "#ef4444",
  default: "var(--text-muted)",
};

const TYPE_ICONS: Record<string, string> = {
  api_key: "🔑",
  oauth2: "🔐",
  jwt: "🎫",
  basic: "👤",
  hmac: "🔒",
  webhook_secret: "🪝",
};

async function apiFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const r = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json" }, ...opts,
  });
  if (!r.ok) throw new Error(`${r.status} ${r.statusText}`);
  return r.json();
}

export function CredentialsPage() {
  const [creds, setCreds] = useState<Credential[]>([]);
  const [loading, setLoading] = useState(false);
  const [filterTenant, setFilterTenant] = useState("tenant-default");
  const [filterProvider, setFilterProvider] = useState("");
  const [showNew, setShowNew] = useState(false);
  const [rotating, setRotating] = useState<string | null>(null);
  const [newSecret, setNewSecret] = useState("");

  // New credential form
  const [form, setForm] = useState({
    name: "", provider: "anthropic", credential_type: "api_key",
    secret: "", description: "", tenant_id: "tenant-default", agent_id: "",
    scopes: "",
  });

  const load = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filterTenant) params.set("tenant_id", filterTenant);
      if (filterProvider) params.set("provider", filterProvider);
      const data = await apiFetch<Credential[]>(`/credentials/?${params}`);
      setCreds(data);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const create = async () => {
    if (!form.name || !form.secret) return;
    try {
      await apiFetch("/credentials/", {
        method: "POST",
        body: JSON.stringify({
          ...form,
          agent_id: form.agent_id || undefined,
          scopes: form.scopes ? form.scopes.split(",").map((s) => s.trim()) : [],
        }),
      });
      setShowNew(false);
      setForm({ name: "", provider: "anthropic", credential_type: "api_key", secret: "", description: "", tenant_id: "tenant-default", agent_id: "", scopes: "" });
      load();
    } catch (e) { alert(String(e)); }
  };

  const rotate = async (cred: Credential) => {
    if (!newSecret.trim()) return;
    try {
      await apiFetch(`/credentials/${cred.cred_id}`, {
        method: "PATCH",
        body: JSON.stringify({ secret: newSecret }),
      });
      setRotating(null);
      setNewSecret("");
      load();
    } catch (e) { alert(String(e)); }
  };

  const toggle = async (cred: Credential) => {
    try {
      await apiFetch(`/credentials/${cred.cred_id}`, {
        method: "PATCH",
        body: JSON.stringify({ active: !cred.active }),
      });
      load();
    } catch (e) { alert(String(e)); }
  };

  const del = async (cred: Credential) => {
    if (!confirm(`Delete "${cred.name}"? This cannot be undone.`)) return;
    try {
      await apiFetch(`/credentials/${cred.cred_id}`, { method: "DELETE" });
      load();
    } catch (e) { alert(String(e)); }
  };

  const fmt = (iso?: string) => iso ? new Date(iso).toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" }) : "never";
  const provColor = (p: string) => PROVIDER_COLORS[p.toLowerCase()] ?? PROVIDER_COLORS.default;

  const inp = (style?: React.CSSProperties): React.CSSProperties => ({
    padding: "7px 10px", borderRadius: 6, border: "1px solid var(--border)",
    background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
    width: "100%", boxSizing: "border-box" as const, ...style,
  });

  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>Credentials</h1>
          <p style={{ margin: "4px 0 0", color: "var(--text-muted)", fontSize: 13 }}>
            Write-only secret vault — secrets never appear after creation
          </p>
        </div>
        <button onClick={() => setShowNew(true)} style={{
          padding: "8px 16px", borderRadius: 6, border: "none",
          background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13,
        }}>+ Add Credential</button>
      </div>

      {/* Filters */}
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        {[
          { ph: "Tenant ID", val: filterTenant, set: setFilterTenant },
          { ph: "Provider", val: filterProvider, set: setFilterProvider },
        ].map(({ ph, val, set }) => (
          <input key={ph} placeholder={ph} value={val} onChange={(e) => set(e.target.value)}
            style={{ padding: "6px 10px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", fontSize: 13, width: 180 }}
          />
        ))}
        <button onClick={load} style={{ padding: "6px 14px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", cursor: "pointer", fontSize: 13 }}>
          {loading ? "…" : "Load"}
        </button>
      </div>

      {/* New credential modal */}
      {showNew && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100 }}>
          <div style={{ background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 10, padding: 24, width: 460 }}>
            <h3 style={{ margin: "0 0 16px" }}>New Credential</h3>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 10 }}>
              {[
                { label: "Name *", key: "name", ph: "Anthropic prod key" },
                { label: "Tenant ID", key: "tenant_id", ph: "tenant-default" },
                { label: "Agent ID (opt)", key: "agent_id", ph: "agent-abc" },
                { label: "Scopes (csv)", key: "scopes", ph: "read,write" },
              ].map(({ label, key, ph }) => (
                <div key={key}>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>{label}</div>
                  <input value={(form as any)[key]} onChange={(e) => setForm({ ...form, [key]: e.target.value })} placeholder={ph} style={inp()} />
                </div>
              ))}
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 10 }}>
              <div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Provider</div>
                <select value={form.provider} onChange={(e) => setForm({ ...form, provider: e.target.value })} style={inp()}>
                  {["anthropic","openai","stripe","paypal","shopify","github","slack","google","azure","custom"].map((p) => <option key={p} value={p}>{p}</option>)}
                </select>
              </div>
              <div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Type</div>
                <select value={form.credential_type} onChange={(e) => setForm({ ...form, credential_type: e.target.value })} style={inp()}>
                  {["api_key","oauth2","jwt","basic","hmac","webhook_secret"].map((t) => <option key={t} value={t}>{t}</option>)}
                </select>
              </div>
            </div>
            <div style={{ marginBottom: 10 }}>
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Description</div>
              <input value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} placeholder="Production API key for..." style={inp()} />
            </div>
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 3 }}>Secret * (write-only — never shown again)</div>
              <input type="password" value={form.secret} onChange={(e) => setForm({ ...form, secret: e.target.value })} placeholder="sk-ant-..." style={inp()} />
            </div>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button onClick={() => setShowNew(false)} style={{ padding: "8px 14px", borderRadius: 6, border: "1px solid var(--border)", background: "transparent", color: "var(--text)", cursor: "pointer" }}>Cancel</button>
              <button onClick={create} disabled={!form.name || !form.secret} style={{ padding: "8px 16px", borderRadius: 6, border: "none", background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600 }}>Save</button>
            </div>
          </div>
        </div>
      )}

      {/* Credential list */}
      {loading && <div style={{ color: "var(--text-muted)", fontSize: 13 }}>Loading…</div>}
      {!loading && creds.length === 0 && (
        <div style={{ background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: 24, textAlign: "center", color: "var(--text-muted)", fontSize: 13 }}>
          No credentials stored yet.
        </div>
      )}
      {creds.map((cred) => (
        <div key={cred.id} style={{
          background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8,
          padding: "14px 16px", marginBottom: 10,
          opacity: cred.active ? 1 : 0.55,
        }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
                <span style={{ fontWeight: 700, fontSize: 14 }}>{cred.name}</span>
                <span style={{ fontSize: 11, padding: "2px 7px", borderRadius: 10, background: provColor(cred.provider) + "22", color: provColor(cred.provider), fontWeight: 600 }}>
                  {cred.provider}
                </span>
                <span style={{ fontSize: 12, color: "var(--text-muted)" }}>
                  {TYPE_ICONS[cred.credential_type] ?? "🔑"} {cred.credential_type}
                </span>
                {!cred.active && <span style={{ fontSize: 10, color: "var(--error)", fontWeight: 700 }}>INACTIVE</span>}
              </div>
              {cred.description && <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 3 }}>{cred.description}</div>}
              <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 4, display: "flex", gap: 14, flexWrap: "wrap" }}>
                <span>Tenant: {cred.tenant_id}</span>
                {cred.agent_id && <span>Agent: {cred.agent_id}</span>}
                <span>Last used: {fmt(cred.last_used_at)}</span>
                <span>Created: {fmt(cred.created_at)}</span>
                {cred.expires_at && <span style={{ color: "var(--error)" }}>Expires: {fmt(cred.expires_at)}</span>}
              </div>
              {cred.scopes?.length > 0 && (
                <div style={{ marginTop: 5, display: "flex", gap: 4, flexWrap: "wrap" }}>
                  {cred.scopes.map((s) => (
                    <span key={s} style={{ fontSize: 10, padding: "1px 6px", borderRadius: 4, background: "var(--surface-2)", border: "1px solid var(--border)" }}>{s}</span>
                  ))}
                </div>
              )}
            </div>

            {/* Secret mask */}
            <div style={{ fontFamily: "monospace", fontSize: 14, color: "var(--text-muted)", padding: "4px 10px", background: "var(--surface-2)", borderRadius: 6, marginLeft: 16, letterSpacing: 2 }}>
              ••••••••
            </div>
          </div>

          {/* Actions */}
          <div style={{ marginTop: 10, display: "flex", gap: 6, flexWrap: "wrap" }}>
            <button onClick={() => { setRotating(cred.cred_id); setNewSecret(""); }} style={{ padding: "4px 10px", fontSize: 12, borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", cursor: "pointer" }}>
              Rotate
            </button>
            <button onClick={() => toggle(cred)} style={{ padding: "4px 10px", fontSize: 12, borderRadius: 6, border: "none", background: cred.active ? "var(--error)22" : "var(--success)22", color: cred.active ? "var(--error)" : "var(--success)", cursor: "pointer", fontWeight: 600 }}>
              {cred.active ? "Deactivate" : "Activate"}
            </button>
            <button onClick={() => del(cred)} style={{ padding: "4px 10px", fontSize: 12, borderRadius: 6, border: "none", background: "var(--error)22", color: "var(--error)", cursor: "pointer" }}>
              Delete
            </button>
          </div>

          {/* Rotate inline */}
          {rotating === cred.cred_id && (
            <div style={{ marginTop: 10, display: "flex", gap: 8, alignItems: "center" }}>
              <input type="password" placeholder="New secret…" value={newSecret} onChange={(e) => setNewSecret(e.target.value)}
                style={{ flex: 1, padding: "7px 10px", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", fontSize: 13 }}
              />
              <button onClick={() => rotate(cred)} disabled={!newSecret} style={{ padding: "7px 14px", borderRadius: 6, border: "none", background: "var(--accent)", color: "#fff", cursor: "pointer", fontWeight: 600, fontSize: 13 }}>Save</button>
              <button onClick={() => setRotating(null)} style={{ padding: "7px 10px", borderRadius: 6, border: "1px solid var(--border)", background: "transparent", color: "var(--text)", cursor: "pointer", fontSize: 13 }}>Cancel</button>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
