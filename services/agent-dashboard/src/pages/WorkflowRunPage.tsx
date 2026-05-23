import { useEffect, useState } from "react";
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

// Types
interface RunStats {
  task_counts: Record<string, number>;
  artifact_counts: Record<string, number>;
  total_tasks: number;
  total_artifacts: number;
  total_cost_usd: number;
  total_tokens: number;
  total_model_calls: number;
}

interface WorkflowRun {
  objective: Record<string, unknown>;
  tasks: Record<string, unknown>[];
  artifacts: Record<string, unknown>[];
  trust_records: Record<string, unknown>[];
  stats: RunStats;
}

interface RunSummary {
  id: string;
  goal: string;
  status: string;
  created_at: string;
  task_count?: number;
  artifact_count?: number;
}

const TASK_STATUSES = ["pending", "running", "completed", "failed", "skipped"];
const STATUS_COLORS: Record<string, string> = {
  pending: "var(--text-muted)",
  running: "#3b82f6",
  completed: "var(--green)",
  failed: "var(--red)",
  skipped: "var(--text-muted)",
  passed: "var(--green)",
  manual_review: "#f59e0b",
};

export function WorkflowRunPage() {
  const [runs, setRuns] = useState<RunSummary[]>([]);
  const [selectedRun, setSelectedRun] = useState<WorkflowRun | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [loadingList, setLoadingList] = useState(false);
  const [loadingRun, setLoadingRun] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Quick-submit form
  const [goal, setGoal] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadRuns();
  }, []);

  async function loadRuns() {
    setLoadingList(true);
    setError(null);
    try {
      const rows = await get<RunSummary[]>("/workflow/");
      setRuns(rows);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoadingList(false);
    }
  }

  async function openRun(id: string) {
    const raw = id.toString().replace(/^objective:/, "");
    setSelectedId(raw);
    setLoadingRun(true);
    setSelectedRun(null);
    try {
      const run = await get<WorkflowRun>(`/workflow/${raw}`);
      setSelectedRun(run);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoadingRun(false);
    }
  }

  async function submitRun(e: React.FormEvent) {
    e.preventDefault();
    if (!goal.trim()) return;
    setSubmitting(true);
    setError(null);
    try {
      const res = await post<{ objective: { id: string } }>("/objectives/run", { goal: goal.trim(), priority: 7 });
      setGoal("");
      await loadRuns();
      await openRun(res.objective.id);
    } catch (e) {
      setError(String(e));
    } finally {
      setSubmitting(false);
    }
  }

  async function updateTaskStatus(taskId: string, status: string) {
    const id = String(taskId).replace(/^task:/, "");
    try {
      await post(`/tasks/${id}/status`, { status });
      if (selectedId) await openRun(selectedId);
    } catch (e) {
      setError(String(e));
    }
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Workflow Runs</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          End-to-end execution view: objective → tasks → artifacts → trust evaluations → cost.
        </p>
      </div>

      {/* Submit new run */}
      <Card title="New Run">
        <form onSubmit={submitRun} style={{ display: "flex", gap: 10 }}>
          <input
            value={goal}
            onChange={(e) => setGoal(e.target.value)}
            placeholder="Describe the objective goal…"
            style={{ ...inputStyle, flex: 1 }}
          />
          <button type="submit" disabled={submitting || !goal.trim()} style={primaryBtn}>
            {submitting ? "Submitting…" : "Run"}
          </button>
        </form>
      </Card>

      {error && (
        <div style={{ padding: "10px 14px", borderRadius: 8, border: "1px solid var(--red)", color: "var(--red)", fontSize: 13 }}>
          {error}
        </div>
      )}

      <div style={{ display: "grid", gridTemplateColumns: "280px 1fr", gap: 16, alignItems: "start" }}>

        {/* Run list */}
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 2 }}>
            <span style={{ fontSize: 12, fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em" }}>
              Runs ({runs.length})
            </span>
            <button onClick={loadRuns} disabled={loadingList} style={{ fontSize: 11, color: "var(--accent)", background: "none", border: "none", cursor: "pointer" }}>
              {loadingList ? "…" : "↻ refresh"}
            </button>
          </div>

          {runs.length === 0 && !loadingList && (
            <div style={{ fontSize: 13, color: "var(--text-muted)", padding: "12px 0" }}>No runs yet. Submit one above.</div>
          )}

          {runs.map((r) => {
            const rid = String(r.id).replace(/^objective:/, "");
            const isActive = selectedId === rid;
            return (
              <button
                key={rid}
                onClick={() => openRun(rid)}
                style={{
                  textAlign: "left", width: "100%", padding: "10px 12px",
                  borderRadius: 8, cursor: "pointer",
                  border: `1px solid ${isActive ? "var(--accent)" : "var(--border)"}`,
                  background: isActive ? "rgba(99,102,241,0.08)" : "var(--surface-2)",
                  display: "flex", flexDirection: "column", gap: 4,
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <StatusBadge status={r.status ?? "pending"} />
                  <span style={{ fontSize: 10, color: "var(--text-muted)" }}>
                    {new Date(r.created_at).toLocaleTimeString()}
                  </span>
                </div>
                <span style={{ fontSize: 12, color: "var(--text)", lineHeight: 1.4, overflow: "hidden", display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical" }}>
                  {String(r.goal ?? "—")}
                </span>
                <div style={{ display: "flex", gap: 10, fontSize: 10, color: "var(--text-muted)" }}>
                  {r.task_count != null && <span>{r.task_count} tasks</span>}
                  {r.artifact_count != null && <span>{r.artifact_count} artifacts</span>}
                </div>
              </button>
            );
          })}
        </div>

        {/* Run detail */}
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          {loadingRun && (
            <div style={{ padding: 20, textAlign: "center", color: "var(--text-muted)", fontSize: 13 }}>Loading run…</div>
          )}

          {selectedRun && !loadingRun && (
            <>
              {/* Header */}
              <Card title="Objective">
                <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
                  <div style={{ display: "flex", justifyContent: "space-between" }}>
                    <span style={{ fontSize: 15, fontWeight: 600 }}>{String(selectedRun.objective.goal ?? "—")}</span>
                    <StatusBadge status={String(selectedRun.objective.status ?? "pending")} />
                  </div>
                  <code style={{ fontSize: 11, color: "var(--text-muted)" }}>{String(selectedRun.objective.id ?? "")}</code>
                  <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
                    {selectedRun.objective.created_at ? new Date(String(selectedRun.objective.created_at)).toLocaleString() : ""}
                  </div>
                </div>
              </Card>

              {/* Stats bar */}
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10 }}>
                <StatChip label="Tasks" value={selectedRun.stats.total_tasks} />
                <StatChip label="Artifacts" value={selectedRun.stats.total_artifacts} />
                <StatChip label="Cost" value={`$${selectedRun.stats.total_cost_usd.toFixed(4)}`} />
                <StatChip label="Tokens" value={selectedRun.stats.total_tokens.toLocaleString()} />
              </div>

              {/* Task breakdown */}
              <div style={{ display: "flex", gap: 8 }}>
                {TASK_STATUSES.map((s) => {
                  const count = selectedRun.stats.task_counts[s] ?? 0;
                  return (
                    <div key={s} style={{ flex: 1, padding: "6px 8px", borderRadius: 6, background: "var(--surface-2)", border: "1px solid var(--border)", textAlign: "center" }}>
                      <div style={{ fontSize: 16, fontWeight: 700, color: STATUS_COLORS[s] ?? "var(--text)" }}>{count}</div>
                      <div style={{ fontSize: 10, color: "var(--text-muted)" }}>{s}</div>
                    </div>
                  );
                })}
              </div>

              {/* Tasks */}
              {selectedRun.tasks.length > 0 && (
                <Card title={`Tasks (${selectedRun.tasks.length})`}>
                  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                    {selectedRun.tasks.map((task, i) => (
                      <TaskRow
                        key={String(task.id ?? i)}
                        task={task}
                        onStatusChange={(status) => updateTaskStatus(String(task.id), status)}
                      />
                    ))}
                  </div>
                </Card>
              )}

              {selectedRun.tasks.length === 0 && (
                <Card title="Tasks">
                  <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
                    No tasks yet. Tasks are created when an agent decomposes this objective.
                  </p>
                  <QuickAddTask objectiveId={selectedId!} onAdded={() => openRun(selectedId!)} />
                </Card>
              )}

              {/* Artifacts */}
              {selectedRun.artifacts.length > 0 && (
                <Card title={`Artifacts (${selectedRun.artifacts.length})`}>
                  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                    {selectedRun.artifacts.map((a, i) => (
                      <ArtifactRow key={String(a.id ?? i)} artifact={a} />
                    ))}
                  </div>
                </Card>
              )}

              {/* Trust records */}
              {selectedRun.trust_records.length > 0 && (
                <Card title={`Trust evaluations (${selectedRun.trust_records.length})`}>
                  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                    {selectedRun.trust_records.map((t, i) => (
                      <TrustRow key={String(t.id ?? i)} record={t} />
                    ))}
                  </div>
                </Card>
              )}
            </>
          )}

          {!selectedRun && !loadingRun && !selectedId && (
            <div style={{ padding: 40, textAlign: "center", color: "var(--text-muted)", fontSize: 13, border: "1px dashed var(--border)", borderRadius: 10 }}>
              Select a run from the list to view the execution graph.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function TaskRow({ task: t, onStatusChange }: { task: Record<string, unknown>; onStatusChange: (s: string) => void }) {
  const status = String(t.status ?? "pending");
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", padding: "8px 0", borderBottom: "1px solid var(--border)", gap: 10 }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 500 }}>{String(t.name ?? "Unnamed task")}</div>
        {t.agent_id && <div style={{ fontSize: 11, color: "var(--text-muted)" }}>→ {String(t.agent_id)}</div>}
        {t.error && <div style={{ fontSize: 11, color: "var(--red)", marginTop: 2 }}>{String(t.error)}</div>}
      </div>
      <div style={{ display: "flex", gap: 8, alignItems: "center", flexShrink: 0 }}>
        {status === "pending" && (
          <button onClick={() => onStatusChange("running")} style={{ ...actionBtn, color: "#3b82f6", borderColor: "#3b82f6" }}>
            Start
          </button>
        )}
        {status === "running" && (
          <>
            <button onClick={() => onStatusChange("completed")} style={{ ...actionBtn, color: "var(--green)", borderColor: "var(--green)" }}>Done</button>
            <button onClick={() => onStatusChange("failed")} style={{ ...actionBtn, color: "var(--red)", borderColor: "var(--red)" }}>Fail</button>
          </>
        )}
        <StatusBadge status={status} />
      </div>
    </div>
  );
}

function ArtifactRow({ artifact: a }: { artifact: Record<string, unknown> }) {
  const evalStatus = String(a.eval_status ?? "pending");
  const score = a.trust_score != null ? Number(a.trust_score) : null;
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 0", borderBottom: "1px solid var(--border)", gap: 10 }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13 }}>{String(a.name ?? "Untitled artifact")}</div>
        <div style={{ fontSize: 11, color: "var(--text-muted)" }}>{String(a.encoding_format ?? "")}</div>
      </div>
      <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
        {score != null && (
          <span style={{ fontFamily: "monospace", fontSize: 13, color: score >= 0.7 ? "var(--green)" : "var(--red)", fontWeight: 600 }}>
            {score.toFixed(3)}
          </span>
        )}
        <StatusBadge status={evalStatus} />
      </div>
    </div>
  );
}

function TrustRow({ record: t }: { record: Record<string, unknown> }) {
  const score = Number(t.rating_value ?? 0);
  const evidence = (t.evidence as { dimension: string; score: number }[]) ?? [];
  return (
    <div style={{ padding: "8px 12px", borderRadius: 6, background: "var(--surface-2)", border: "1px solid var(--border)" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
        <StatusBadge status={String(t.eval_status ?? "pending")} />
        <span style={{ fontFamily: "monospace", fontWeight: 700, fontSize: 16, color: score >= 0.7 ? "var(--green)" : "var(--red)" }}>
          {score.toFixed(3)}
        </span>
      </div>
      <div style={{ display: "flex", gap: 12 }}>
        {evidence.map((e) => (
          <div key={e.dimension} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2, fontSize: 11 }}>
            <span style={{ color: "var(--text-muted)" }}>{e.dimension}</span>
            <span style={{ fontFamily: "monospace", color: e.score >= 0.7 ? "var(--green)" : "var(--red)" }}>{e.score.toFixed(2)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function QuickAddTask({ objectiveId, onAdded }: { objectiveId: string; onAdded: () => void }) {
  const [name, setName] = useState("");
  const [adding, setAdding] = useState(false);
  async function add(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setAdding(true);
    try {
      await post("/tasks/", { name: name.trim(), objective_id: objectiveId });
      setName("");
      onAdded();
    } catch { /* ignore */ } finally {
      setAdding(false);
    }
  }
  return (
    <form onSubmit={add} style={{ display: "flex", gap: 8, marginTop: 12 }}>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Add a task…" style={{ ...inputStyle, flex: 1 }} />
      <button type="submit" disabled={adding || !name.trim()} style={{ ...primaryBtn, fontSize: 12 }}>{adding ? "…" : "Add"}</button>
    </form>
  );
}

function StatChip({ label, value }: { label: string; value: string | number }) {
  return (
    <div style={{ background: "var(--surface-2)", border: "1px solid var(--border)", borderRadius: 8, padding: "10px 14px", textAlign: "center" }}>
      <div style={{ fontSize: 18, fontWeight: 700 }}>{value}</div>
      <div style={{ fontSize: 10, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em" }}>{label}</div>
    </div>
  );
}

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
const actionBtn: React.CSSProperties = {
  padding: "3px 10px", borderRadius: 5, border: "1px solid",
  background: "transparent", fontSize: 11, cursor: "pointer", fontWeight: 600,
};
