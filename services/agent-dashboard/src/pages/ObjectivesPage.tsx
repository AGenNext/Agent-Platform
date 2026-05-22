import { useState } from "react";
import { api, type ObjectiveRecord } from "../api/client";
import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";

export function ObjectivesPage() {
  const [goal, setGoal] = useState("");
  const [priority, setPriority] = useState(5);
  const [running, setRunning] = useState(false);
  const [results, setResults] = useState<ObjectiveRecord[]>([]);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!goal.trim()) return;
    setRunning(true);
    setError(null);
    try {
      const res = await api.runObjective({ goal: goal.trim(), priority });
      setResults((prev) => [res.objective, ...prev]);
      setGoal("");
    } catch (e) {
      setError(String(e));
    } finally {
      setRunning(false);
    }
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>
          Objectives
        </h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Submit and track agent objectives.
        </p>
      </div>

      <Card title="Run Objective">
        <form onSubmit={submit} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <div>
            <label style={labelStyle}>Goal</label>
            <textarea
              value={goal}
              onChange={(e) => setGoal(e.target.value)}
              rows={3}
              placeholder="Describe the objective goal…"
              style={inputStyle}
            />
          </div>
          <div>
            <label style={labelStyle}>Priority (1–10)</label>
            <input
              type="number"
              min={1}
              max={10}
              value={priority}
              onChange={(e) => setPriority(Number(e.target.value))}
              style={{ ...inputStyle, width: 80 }}
            />
          </div>
          {error && (
            <div style={{ color: "var(--red)", fontSize: 13 }}>{error}</div>
          )}
          <button
            type="submit"
            disabled={running || !goal.trim()}
            style={{
              alignSelf: "flex-start",
              padding: "8px 18px",
              borderRadius: 7,
              border: "none",
              background: "var(--accent)",
              color: "#fff",
              fontWeight: 600,
              fontSize: 14,
              opacity: running || !goal.trim() ? 0.5 : 1,
            }}
          >
            {running ? "Running…" : "Run"}
          </button>
        </form>
      </Card>

      {results.length > 0 && (
        <Card title="Results">
          <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            {results.map((r) => (
              <ObjectiveRow key={r.id} record={r} />
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}

function ObjectiveRow({ record }: { record: ObjectiveRecord }) {
  const [open, setOpen] = useState(false);
  return (
    <div
      style={{
        background: "var(--surface-2)",
        border: "1px solid var(--border)",
        borderRadius: 8,
        padding: 14,
      }}
    >
      <div
        style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", cursor: "pointer" }}
        onClick={() => setOpen((o) => !o)}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
          <span style={{ fontWeight: 600, fontSize: 14 }}>{record.goal}</span>
          <span style={{ fontSize: 11, color: "var(--text-muted)" }}>
            {record.id} · priority {record.priority}
          </span>
        </div>
        <StatusBadge status={record.status} />
      </div>

      {open && record.result && (
        <pre
          style={{
            marginTop: 12,
            padding: 12,
            background: "var(--bg)",
            borderRadius: 6,
            fontSize: 12,
            color: "var(--text-muted)",
            overflowX: "auto",
            whiteSpace: "pre-wrap",
            wordBreak: "break-word",
          }}
        >
          {JSON.stringify(record.result, null, 2)}
        </pre>
      )}
    </div>
  );
}

const labelStyle: React.CSSProperties = {
  display: "block",
  fontSize: 12,
  fontWeight: 600,
  color: "var(--text-muted)",
  marginBottom: 6,
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
  resize: "vertical",
};
