import { useEffect, useState } from "react";
import { api, type HealthResponse } from "../api/client";
import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";

const services = [
  { name: "SurrealDB", url: "http://localhost:8000", port: 8000 },
  { name: "Agent Knowledge API", url: "http://localhost:8001", port: 8001 },
  { name: "MinIO", url: "http://localhost:9000", port: 9000 },
];

export function HealthPage() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const h = await api.health();
      setHealth(h);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
    const t = setInterval(refresh, 10_000);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>
          Platform Health
        </h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Live status of all local platform services.
        </p>
      </div>

      <Card
        title="API Health"
        action={
          <button
            onClick={refresh}
            style={{
              fontSize: 12,
              padding: "4px 10px",
              borderRadius: 6,
              border: "1px solid var(--border)",
              background: "transparent",
              color: "var(--text-muted)",
            }}
          >
            Refresh
          </button>
        }
      >
        {loading && <span style={{ color: "var(--text-muted)" }}>Checking…</span>}
        {error && (
          <div style={{ color: "var(--red)", fontSize: 13 }}>
            API unreachable — {error}
          </div>
        )}
        {health && !loading && (
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <Row label="Service" value={health.service} />
            <Row label="Version" value={health.version} />
            <Row label="API Status" value={<StatusBadge status={health.status} />} />
            <Row label="Database" value={<StatusBadge status={health.db} />} />
          </div>
        )}
      </Card>

      <Card title="Services">
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          {services.map((s) => (
            <Row
              key={s.name}
              label={s.name}
              value={
                <a
                  href={s.url}
                  target="_blank"
                  rel="noreferrer"
                  style={{ fontSize: 12, color: "var(--text-muted)" }}
                >
                  :{s.port}
                </a>
              }
            />
          ))}
        </div>
      </Card>
    </div>
  );
}

function Row({
  label,
  value,
}: {
  label: string;
  value: React.ReactNode;
}) {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        paddingBottom: 12,
        borderBottom: "1px solid var(--border)",
      }}
    >
      <span style={{ color: "var(--text-muted)", fontSize: 13 }}>{label}</span>
      <span style={{ fontSize: 13 }}>{value}</span>
    </div>
  );
}
