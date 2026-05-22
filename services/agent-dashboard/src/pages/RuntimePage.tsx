import { Card } from "../components/Card";

export function RuntimePage() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>
          Runtime
        </h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Live SurrealDB state — objectives, tasks, A2A traces.
        </p>
      </div>

      <Card title="SurrealDB">
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <InfoRow label="URL" value="ws://localhost:8000/rpc" />
          <InfoRow label="Namespace" value="agent_platform" />
          <InfoRow label="Database" value="agent_platform" />
          <InfoRow label="Runtime principle" value="data + decisions at same layer" />
        </div>
      </Card>

      <Card title="Traces">
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          A2A trace view coming in M3 — objective and task records will stream
          here via SurrealDB live queries.
        </p>
      </Card>

      <Card title="Runtime Tables">
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {["objective", "task", "trace", "checkpoint", "event"].map((t) => (
            <div
              key={t}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                padding: "8px 0",
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
                }}
              >
                {t}
              </span>
              <span style={{ color: "var(--text-muted)" }}>
                SurrealDB table
              </span>
            </div>
          ))}
        </div>
      </Card>
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
