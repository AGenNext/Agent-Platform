import { useState } from "react";
import { api, type AgentRecord } from "../api/client";
import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";
import { useLiveQuery } from "../hooks/useLiveQuery";

const REQUIRED_CAPS = ["analytics", "billing", "health", "tracing", "auth", "artifacts", "skills", "trust"];

const defaultCaps = Object.fromEntries(REQUIRED_CAPS.map((c) => [c, true]));

export function AgentsPage() {
  const agents = useLiveQuery<AgentRecord>(
    "SELECT * FROM agent ORDER BY registered_at DESC LIMIT 50"
  );

  const [form, setForm] = useState({
    name: "",
    tenant_id: "tenant-default",
    description: "",
    capabilities: { ...defaultCaps } as Record<string, boolean>,
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  async function register(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);
    try {
      const agent = await api.registerAgent({
        name: form.name,
        tenant_id: form.tenant_id,
        description: form.description || undefined,
        capabilities: form.capabilities,
      });
      setSuccess(`Agent "${agent.name}" registered — ID: ${agent.agent_id}`);
      setForm({ name: "", tenant_id: "tenant-default", description: "", capabilities: { ...defaultCaps } });
    } catch (e) {
      setError(String(e));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Agents</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Register agents and inspect the live registry. All 8 capabilities required — the DB rejects incomplete agents.
        </p>
      </div>

      <Card title="Register Agent">
        <form onSubmit={register} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <FieldRow>
            <Field label="Name">
              <input
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="e.g. Researcher"
                style={inputStyle}
                required
              />
            </Field>
            <Field label="Tenant ID">
              <input
                value={form.tenant_id}
                onChange={(e) => setForm((f) => ({ ...f, tenant_id: e.target.value }))}
                style={inputStyle}
                required
              />
            </Field>
          </FieldRow>

          <Field label="Description (optional)">
            <input
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
              placeholder="What does this agent do?"
              style={inputStyle}
            />
          </Field>

          <Field label="Capabilities">
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 4 }}>
              {REQUIRED_CAPS.map((cap) => (
                <label
                  key={cap}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 5,
                    fontSize: 13,
                    cursor: "pointer",
                    padding: "4px 10px",
                    borderRadius: 6,
                    border: `1px solid ${form.capabilities[cap] ? "var(--green)" : "var(--border)"}`,
                    background: form.capabilities[cap] ? "rgba(72,187,120,0.08)" : "var(--surface-2)",
                    color: form.capabilities[cap] ? "var(--green)" : "var(--text-muted)",
                  }}
                >
                  <input
                    type="checkbox"
                    checked={!!form.capabilities[cap]}
                    onChange={(e) =>
                      setForm((f) => ({
                        ...f,
                        capabilities: { ...f.capabilities, [cap]: e.target.checked },
                      }))
                    }
                    style={{ display: "none" }}
                  />
                  {cap}
                </label>
              ))}
            </div>
            <p style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 6 }}>
              All 8 must be enabled. The DB enforces this via ASSERT — unchecking any will cause a 422.
            </p>
          </Field>

          {error && <div style={{ color: "var(--red)", fontSize: 13 }}>{error}</div>}
          {success && <div style={{ color: "var(--green)", fontSize: 13 }}>{success}</div>}

          <button
            type="submit"
            disabled={submitting || !form.name.trim()}
            style={{
              alignSelf: "flex-start",
              padding: "8px 18px",
              borderRadius: 7,
              border: "none",
              background: "var(--accent)",
              color: "#fff",
              fontWeight: 600,
              fontSize: 14,
              cursor: submitting ? "not-allowed" : "pointer",
              opacity: submitting || !form.name.trim() ? 0.5 : 1,
            }}
          >
            {submitting ? "Registering…" : "Register"}
          </button>
        </form>
      </Card>

      <Card
        title={`Registry (${agents.data.length})`}
        action={
          agents.error ? (
            <span style={{ fontSize: 12, color: "var(--red)" }}>{agents.error}</span>
          ) : (
            <StatusBadge status={agents.connected ? "connected" : "disconnected"} />
          )
        }
      >
        {agents.data.length === 0 ? (
          <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
            No agents registered yet.
          </p>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {agents.data.map((a) => (
              <AgentCard key={a.agent_id} agent={a} />
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}

function AgentCard({ agent }: { agent: AgentRecord }) {
  const [expanded, setExpanded] = useState(false);
  const caps = Object.entries(agent.capabilities ?? {});
  const missing = caps.filter(([, v]) => !v).map(([k]) => k);

  return (
    <div
      style={{
        background: "var(--surface-2)",
        border: `1px solid ${missing.length > 0 ? "var(--red)" : "var(--border)"}`,
        borderRadius: 8,
        padding: 14,
        display: "flex",
        flexDirection: "column",
        gap: 8,
      }}
    >
      <div
        style={{ display: "flex", justifyContent: "space-between", alignItems: "center", cursor: "pointer" }}
        onClick={() => setExpanded((x) => !x)}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <span style={{ fontWeight: 600, fontSize: 14 }}>{agent.name}</span>
          <span style={{ fontSize: 11, color: "var(--text-muted)", fontFamily: "monospace" }}>
            {agent.agent_id} · {agent.tenant_id}
          </span>
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          {missing.length > 0 && (
            <span style={{ fontSize: 11, color: "var(--red)" }}>
              missing: {missing.join(", ")}
            </span>
          )}
          <StatusBadge status={agent.status} />
        </div>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
        {caps.map(([cap, enabled]) => (
          <span
            key={cap}
            style={{
              fontSize: 10,
              padding: "2px 7px",
              borderRadius: 4,
              background: "var(--bg)",
              color: enabled ? "var(--green)" : "var(--red)",
              border: `1px solid ${enabled ? "var(--border)" : "var(--red)"}`,
            }}
          >
            {cap}
          </span>
        ))}
      </div>

      {expanded && (
        <div style={{ marginTop: 4, display: "flex", flexDirection: "column", gap: 6 }}>
          <InfoRow label="version" value={agent.version} />
          <InfoRow label="registered" value={new Date(agent.registered_at).toLocaleString()} />
          <InfoRow label="last seen" value={new Date(agent.last_seen_at).toLocaleString()} />
          {agent.goal_types?.length > 0 && (
            <InfoRow label="goal types" value={agent.goal_types.join(", ")} />
          )}
        </div>
      )}
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
      <label style={labelStyle}>{label}</label>
      {children}
    </div>
  );
}

function FieldRow({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
      {children}
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", gap: 8, fontSize: 12 }}>
      <span style={{ color: "var(--text-muted)", minWidth: 90 }}>{label}</span>
      <span style={{ fontFamily: "monospace" }}>{value}</span>
    </div>
  );
}

const labelStyle: React.CSSProperties = {
  fontSize: 11,
  fontWeight: 600,
  color: "var(--text-muted)",
  textTransform: "uppercase",
  letterSpacing: "0.06em",
};

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
