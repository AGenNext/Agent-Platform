import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";
import { useLiveQuery } from "../hooks/useLiveQuery";

interface AgentRecord {
  id: string;
  agent_id: string;
  name: string;
  status: string;
  tenant_id: string;
  last_seen_at: string;
  capabilities: Record<string, boolean>;
}

interface ObjectiveRecord {
  id: string;
  goal: string;
  status: string;
  created_at: string;
}

export function RuntimePage() {
  const agents = useLiveQuery<AgentRecord>(
    "SELECT * FROM agent ORDER BY last_seen_at DESC LIMIT 20"
  );
  const objectives = useLiveQuery<ObjectiveRecord>(
    "SELECT * FROM objective ORDER BY created_at DESC LIMIT 10"
  );

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>
          Runtime
        </h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Live SurrealDB state via WebSocket live queries.
        </p>
      </div>

      <Card
        title="SurrealDB Connection"
        action={
          <StatusBadge status={agents.connected ? "connected" : "disconnected"} />
        }
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <InfoRow label="URL" value="ws://localhost:8000/rpc" />
          <InfoRow label="Namespace" value="agent_platform" />
          <InfoRow label="Database" value="agent_platform" />
          <InfoRow label="Query mode" value="LIVE SELECT (WebSocket)" />
        </div>
      </Card>

      <Card
        title={`Agent Registry (${agents.data.length})`}
        action={
          agents.error ? (
            <span style={{ fontSize: 12, color: "var(--red)" }}>
              {agents.error}
            </span>
          ) : undefined
        }
      >
        {agents.data.length === 0 ? (
          <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
            No agents registered yet. Register an agent via POST /agents/register.
          </p>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {agents.data.map((a) => (
              <AgentRow key={a.agent_id} agent={a} />
            ))}
          </div>
        )}
      </Card>

      <Card title={`Live Objectives (${objectives.data.length})`}>
        {objectives.data.length === 0 ? (
          <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
            No objectives yet. Submit one on the Objectives page.
          </p>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {objectives.data.map((o) => (
              <div
                key={o.id}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  padding: "8px 0",
                  borderBottom: "1px solid var(--border)",
                }}
              >
                <span
                  style={{
                    fontSize: 13,
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                    whiteSpace: "nowrap",
                    maxWidth: 400,
                  }}
                >
                  {o.goal}
                </span>
                <StatusBadge status={o.status} />
              </div>
            ))}
          </div>
        )}
      </Card>

      <Card title="Runtime Tables">
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {[
            "objective", "task", "trace", "artifact",
            "agent", "skill", "blueprint", "memory",
            "twin", "health_check", "trust_record",
            "event", "usage_record", "budget",
            "policy", "audit_log", "account",
          ].map((t) => (
            <div
              key={t}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                padding: "6px 0",
                borderBottom: "1px solid var(--border)",
                fontSize: 13,
              }}
            >
              <span
                style={{
                  fontFamily: "monospace",
                  background: "var(--surface-2)",
                  padding: "2px 8px",
                  borderRadius: 4,
                  color: "var(--accent)",
                  fontSize: 12,
                }}
              >
                {t}
              </span>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function AgentRow({ agent }: { agent: AgentRecord }) {
  const caps = Object.entries(agent.capabilities ?? {})
    .filter(([, v]) => v)
    .map(([k]) => k);

  return (
    <div
      style={{
        background: "var(--surface-2)",
        border: "1px solid var(--border)",
        borderRadius: 8,
        padding: 12,
        display: "flex",
        flexDirection: "column",
        gap: 6,
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontWeight: 600, fontSize: 14 }}>{agent.name}</span>
        <StatusBadge status={agent.status} />
      </div>
      <span style={{ fontSize: 11, color: "var(--text-muted)", fontFamily: "monospace" }}>
        {agent.agent_id}
      </span>
      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginTop: 4 }}>
        {caps.map((c) => (
          <span
            key={c}
            style={{
              fontSize: 10,
              padding: "2px 6px",
              borderRadius: 4,
              background: "var(--bg)",
              color: "var(--green)",
              border: "1px solid var(--border)",
            }}
          >
            {c}
          </span>
        ))}
      </div>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        padding: "8px 0",
        borderBottom: "1px solid var(--border)",
        fontSize: 13,
      }}
    >
      <span style={{ color: "var(--text-muted)" }}>{label}</span>
      <span style={{ fontFamily: "monospace", fontSize: 12 }}>{value}</span>
    </div>
  );
}
