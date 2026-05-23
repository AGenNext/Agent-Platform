import { useState } from "react";
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

interface Artifact {
  id: string;
  name?: string;
  description?: string;
  text?: string;
  url?: string;
  encoding_format: string;
  objective_id?: string;
  task_id?: string;
  trust_score?: number;
  eval_status?: string;
  created_at: string;
}

interface TrustRecord {
  id: string;
  artifact_id?: string;
  rating_value: number;
  eval_status: string;
  evidence: { dimension: string; score: number }[];
  reviewer?: string;
  notes?: string;
  evaluated_at: string;
}

const CLEAR_DIMS = [
  { key: "correct",  label: "Correct",         hint: "Factually accurate, no hallucinations" },
  { key: "logical",  label: "Logical",          hint: "Reasoning is sound and coherent" },
  { key: "evidence", label: "Evidence-backed",  hint: "Claims supported by cited sources" },
  { key: "aligned",  label: "Aligned",          hint: "Meets the objective's intent" },
  { key: "readable", label: "Readable",         hint: "Clear, well-structured output" },
] as const;

const SCHEMA_TYPES = ["CreativeWork", "BlogPosting", "Article", "Report", "Dataset", "SoftwareSourceCode"];
const FORMATS = ["text/markdown", "text/plain", "application/json", "text/html", "application/pdf"];

export function ArtifactsPage() {
  const [artifacts, setArtifacts] = useState<Artifact[]>([]);
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loaded, setLoaded] = useState(false);

  // Create artifact form
  const [createOpen, setCreateOpen] = useState(false);
  const [form, setForm] = useState({ name: "", description: "", text: "", objective_id: "", schema_type: "CreativeWork", encoding_format: "text/markdown" });
  const [creating, setCreating] = useState(false);

  // CLEAR eval modal
  const [evalArtifact, setEvalArtifact] = useState<Artifact | null>(null);
  const [scores, setScores] = useState({ correct: 0.8, logical: 0.8, evidence: 0.7, aligned: 0.9, readable: 0.85 });
  const [evalNotes, setEvalNotes] = useState("");
  const [evaluating, setEvaluating] = useState(false);
  const [trustRecords, setTrustRecords] = useState<Record<string, TrustRecord[]>>({});

  async function loadArtifacts() {
    setLoading(true);
    setError(null);
    try {
      const params = filterStatus !== "all" ? `?eval_status=${filterStatus}` : "";
      const rows = await get<Artifact[]>(`/artifacts/${params}`);
      setArtifacts(rows);
      setLoaded(true);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  async function createArtifact(e: React.FormEvent) {
    e.preventDefault();
    setCreating(true);
    try {
      const artifact = await post<Artifact>("/artifacts/", {
        name: form.name || undefined,
        description: form.description || undefined,
        text: form.text || undefined,
        objective_id: form.objective_id || undefined,
        schema_type: form.schema_type,
        encoding_format: form.encoding_format,
      });
      setArtifacts((prev) => [artifact, ...prev]);
      setForm({ name: "", description: "", text: "", objective_id: "", schema_type: "CreativeWork", encoding_format: "text/markdown" });
      setCreateOpen(false);
    } catch (e) {
      setError(String(e));
    } finally {
      setCreating(false);
    }
  }

  async function submitEval(e: React.FormEvent) {
    e.preventDefault();
    if (!evalArtifact) return;
    setEvaluating(true);
    try {
      const id = evalArtifact.id.replace(/^artifact:/, "");
      const record = await post<TrustRecord>("/trust/evaluate", {
        artifact_id: id,
        ...scores,
        notes: evalNotes || undefined,
      });
      setTrustRecords((prev) => ({ ...prev, [id]: [record, ...(prev[id] ?? [])] }));
      setArtifacts((prev) => prev.map((a) =>
        a.id === evalArtifact.id
          ? { ...a, trust_score: record.rating_value, eval_status: record.eval_status }
          : a
      ));
      setEvalArtifact(null);
      setEvalNotes("");
      setScores({ correct: 0.8, logical: 0.8, evidence: 0.7, aligned: 0.9, readable: 0.85 });
    } catch (e) {
      setError(String(e));
    } finally {
      setEvaluating(false);
    }
  }

  async function loadTrust(artifact: Artifact) {
    const id = artifact.id.replace(/^artifact:/, "");
    if (trustRecords[id]) return;
    try {
      const records = await get<TrustRecord[]>(`/trust/artifact/${id}`);
      setTrustRecords((prev) => ({ ...prev, [id]: records }));
    } catch { /* silent */ }
  }

  const displayed = filterStatus === "all" ? artifacts : artifacts.filter((a) => (a.eval_status ?? "pending") === filterStatus);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Artifacts</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          schema:CreativeWork outputs from agent workflows. Every artifact must pass CLEAR evaluation before surfacing to users.
        </p>
      </div>

      {/* Toolbar */}
      <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
        {["all", "pending", "passed", "failed", "manual_review"].map((s) => (
          <button
            key={s}
            onClick={() => setFilterStatus(s)}
            style={{
              padding: "5px 14px", borderRadius: 20, fontSize: 12,
              border: `1px solid ${filterStatus === s ? statusColor(s) : "var(--border)"}`,
              background: filterStatus === s ? `${statusColor(s)}18` : "var(--surface-2)",
              color: filterStatus === s ? statusColor(s) : "var(--text-muted)",
              fontWeight: filterStatus === s ? 600 : 400, cursor: "pointer",
            }}
          >
            {s}
          </button>
        ))}
        <div style={{ flex: 1 }} />
        <button onClick={() => setCreateOpen((o) => !o)} style={secondaryBtn}>+ New artifact</button>
        <button onClick={loadArtifacts} disabled={loading} style={primaryBtn}>{loading ? "Loading…" : "Load"}</button>
      </div>

      {/* Create form */}
      {createOpen && (
        <Card title="New Artifact">
          <form onSubmit={createArtifact} style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
              <Field label="Name"><input value={form.name} onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))} placeholder="Artifact name" style={inputStyle} /></Field>
              <Field label="Objective ID (optional)"><input value={form.objective_id} onChange={(e) => setForm((f) => ({ ...f, objective_id: e.target.value }))} placeholder="objective UUID" style={inputStyle} /></Field>
              <Field label="Schema type">
                <select value={form.schema_type} onChange={(e) => setForm((f) => ({ ...f, schema_type: e.target.value }))} style={inputStyle}>
                  {SCHEMA_TYPES.map((t) => <option key={t}>{t}</option>)}
                </select>
              </Field>
              <Field label="Format">
                <select value={form.encoding_format} onChange={(e) => setForm((f) => ({ ...f, encoding_format: e.target.value }))} style={inputStyle}>
                  {FORMATS.map((f) => <option key={f}>{f}</option>)}
                </select>
              </Field>
            </div>
            <Field label="Description"><input value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} style={inputStyle} /></Field>
            <Field label="Content / text">
              <textarea value={form.text} onChange={(e) => setForm((f) => ({ ...f, text: e.target.value }))} rows={4} style={{ ...inputStyle, resize: "vertical" }} placeholder="Artifact content…" />
            </Field>
            <div style={{ display: "flex", gap: 10 }}>
              <button type="submit" disabled={creating} style={primaryBtn}>{creating ? "Creating…" : "Create"}</button>
              <button type="button" onClick={() => setCreateOpen(false)} style={secondaryBtn}>Cancel</button>
            </div>
          </form>
        </Card>
      )}

      {error && <div style={{ padding: "10px 14px", borderRadius: 8, border: "1px solid var(--red)", color: "var(--red)", fontSize: 13 }}>{error}</div>}

      {/* CLEAR eval modal */}
      {evalArtifact && (
        <Card title={`CLEAR Evaluation — ${evalArtifact.name ?? evalArtifact.id}`}>
          <p style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 14 }}>
            Score each dimension 0.0–1.0. Composite ≥ 0.7 = passed. The DB enforces ASSERT ratingValue IN [0,1].
          </p>
          <form onSubmit={submitEval} style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {CLEAR_DIMS.map(({ key, label, hint }) => (
              <div key={key}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                  <label style={{ fontSize: 13, fontWeight: 600 }}>{label}</label>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <input
                      type="range" min={0} max={1} step={0.05}
                      value={scores[key as keyof typeof scores]}
                      onChange={(e) => setScores((s) => ({ ...s, [key]: +e.target.value }))}
                      style={{ width: 120 }}
                    />
                    <span style={{ fontFamily: "monospace", fontSize: 13, minWidth: 32, textAlign: "right" }}>
                      {scores[key as keyof typeof scores].toFixed(2)}
                    </span>
                  </div>
                </div>
                <p style={{ fontSize: 11, color: "var(--text-muted)", margin: 0 }}>{hint}</p>
              </div>
            ))}
            <div style={{ padding: "10px 12px", borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--border)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span style={{ fontSize: 13, color: "var(--text-muted)" }}>Composite score</span>
              <span style={{ fontWeight: 700, fontSize: 18, color: compositeScore(scores) >= 0.7 ? "var(--green)" : "var(--red)" }}>
                {compositeScore(scores).toFixed(3)}
                {compositeScore(scores) >= 0.7 ? " → passed" : " → failed"}
              </span>
            </div>
            <Field label="Notes (optional)">
              <input value={evalNotes} onChange={(e) => setEvalNotes(e.target.value)} placeholder="Evaluation notes…" style={inputStyle} />
            </Field>
            <div style={{ display: "flex", gap: 10 }}>
              <button type="submit" disabled={evaluating} style={primaryBtn}>{evaluating ? "Evaluating…" : "Submit evaluation"}</button>
              <button type="button" onClick={() => setEvalArtifact(null)} style={secondaryBtn}>Cancel</button>
            </div>
          </form>
        </Card>
      )}

      {/* Artifact list */}
      {loaded && displayed.length === 0 && (
        <Card title="No artifacts"><p style={{ color: "var(--text-muted)", fontSize: 13 }}>No artifacts match the current filter.</p></Card>
      )}

      {displayed.length > 0 && (
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {displayed.map((a) => (
            <ArtifactCard
              key={a.id}
              artifact={a}
              trust={trustRecords[a.id.replace(/^artifact:/, "")] ?? []}
              onEvaluate={() => setEvalArtifact(a)}
              onExpand={() => loadTrust(a)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function ArtifactCard({ artifact: a, trust, onEvaluate, onExpand }: { artifact: Artifact; trust: TrustRecord[]; onEvaluate: () => void; onExpand: () => void }) {
  const [open, setOpen] = useState(false);
  const evalStatus = a.eval_status ?? "pending";

  return (
    <div style={{ background: "var(--surface-2)", border: `1px solid var(--border)`, borderLeft: `3px solid ${statusColor(evalStatus)}`, borderRadius: 8, padding: 14 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 10 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 3, flex: 1, cursor: "pointer" }} onClick={() => { setOpen((x) => !x); onExpand(); }}>
          <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
            <span style={{ fontWeight: 600, fontSize: 14 }}>{a.name ?? "Untitled artifact"}</span>
            <span style={{ fontSize: 11, color: "var(--text-muted)", fontFamily: "monospace" }}>{a.encoding_format}</span>
          </div>
          {a.description && <p style={{ fontSize: 12, color: "var(--text-muted)", margin: 0 }}>{a.description}</p>}
          <span style={{ fontSize: 11, color: "var(--text-muted)" }}>{new Date(a.created_at).toLocaleString()}</span>
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center", flexShrink: 0 }}>
          {a.trust_score != null && (
            <span style={{ fontSize: 12, fontFamily: "monospace", color: a.trust_score >= 0.7 ? "var(--green)" : "var(--red)" }}>
              {a.trust_score.toFixed(3)}
            </span>
          )}
          <StatusBadge status={evalStatus} />
          {evalStatus === "pending" && (
            <button onClick={(e) => { e.stopPropagation(); onEvaluate(); }} style={{ ...primaryBtn, fontSize: 11, padding: "4px 10px" }}>
              Evaluate
            </button>
          )}
        </div>
      </div>

      {open && (
        <div style={{ marginTop: 12, display: "flex", flexDirection: "column", gap: 8 }}>
          {a.text && (
            <pre style={{ margin: 0, padding: "10px 12px", background: "var(--bg)", borderRadius: 6, fontSize: 12, whiteSpace: "pre-wrap", wordBreak: "break-word", maxHeight: 200, overflowY: "auto", color: "var(--text-muted)" }}>
              {a.text}
            </pre>
          )}
          {a.objective_id && (
            <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
              Objective: <code>{a.objective_id}</code>
            </div>
          )}
          {trust.length > 0 && (
            <div style={{ marginTop: 4 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 6 }}>
                Trust records ({trust.length})
              </div>
              {trust.map((t) => (
                <TrustSummary key={t.id} record={t} />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function TrustSummary({ record: t }: { record: TrustRecord }) {
  return (
    <div style={{ padding: "8px 12px", borderRadius: 6, background: "var(--bg)", border: "1px solid var(--border)", marginBottom: 6 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
        <StatusBadge status={t.eval_status} />
        <span style={{ fontFamily: "monospace", fontSize: 14, fontWeight: 700, color: t.rating_value >= 0.7 ? "var(--green)" : "var(--red)" }}>
          {t.rating_value.toFixed(3)}
        </span>
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {t.evidence.map((e) => (
          <div key={e.dimension} style={{ fontSize: 11, display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
            <span style={{ color: "var(--text-muted)" }}>{e.dimension}</span>
            <span style={{ fontFamily: "monospace", color: e.score >= 0.7 ? "var(--green)" : "var(--red)" }}>{e.score.toFixed(2)}</span>
          </div>
        ))}
      </div>
      {t.notes && <p style={{ margin: "6px 0 0", fontSize: 11, color: "var(--text-muted)" }}>{t.notes}</p>}
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
      <label style={{ fontSize: 11, fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em" }}>{label}</label>
      {children}
    </div>
  );
}

function compositeScore(s: typeof scores) {
  return (s.correct + s.logical + s.evidence + s.aligned + s.readable) / 5;
}
const scores = { correct: 0, logical: 0, evidence: 0, aligned: 0, readable: 0 };

function statusColor(status: string) {
  switch (status) {
    case "passed": return "var(--green)";
    case "failed": return "var(--red)";
    case "manual_review": return "#f59e0b";
    case "pending": return "var(--text-muted)";
    default: return "var(--border)";
  }
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
const secondaryBtn: React.CSSProperties = {
  padding: "8px 14px", borderRadius: 7, border: "1px solid var(--border)",
  background: "var(--surface-2)", color: "var(--text)", fontSize: 13,
  cursor: "pointer", whiteSpace: "nowrap",
};
