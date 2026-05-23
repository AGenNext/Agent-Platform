import { useState } from "react";
import { api } from "../api/client";
import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";

// Multi-tenant first-run onboarding:
// Step 1 — Tenant setup (name, ID, budget)
// Step 2 — Register first agent (from blueprint)
// Step 3 — Run first objective
// Step 4 — View results + next steps

const STEPS = [
  { key: "tenant",    label: "Tenant",    icon: "01" },
  { key: "agent",     label: "Agent",     icon: "02" },
  { key: "objective", label: "Objective", icon: "03" },
  { key: "done",      label: "Done",      icon: "04" },
] as const;
type StepKey = typeof STEPS[number]["key"];

const BLUEPRINTS = [
  { id: "agent.researcher", name: "Researcher", desc: "Discovers and synthesises information", goals: ["web_research", "source_synthesis"], skills: ["skill.search", "skill.summarize", "skill.cite"] },
  { id: "agent.writer",     name: "Writer",     desc: "Generates written artifacts",           goals: ["write_blog", "write_product_doc"], skills: ["skill.write", "skill.structure", "skill.format"] },
  { id: "agent.orchestrator", name: "Orchestrator", desc: "Decomposes and delegates objectives", goals: ["decompose_objective", "assign_tasks"], skills: ["skill.decompose", "skill.assign", "skill.synthesize"] },
];

const ALL_CAPS = Object.fromEntries(
  ["analytics", "billing", "health", "tracing", "auth", "artifacts", "skills", "trust"].map((c) => [c, true])
);

interface Result {
  tenantId: string;
  agentId: string;
  agentName: string;
  objectiveId: string;
  goal: string;
  status: string;
}

export function OnboardingPage() {
  const [step, setStep] = useState<StepKey>("tenant");
  const [result, setResult] = useState<Partial<Result>>({});
  const [error, setError] = useState<string | null>(null);

  // Step 1 state
  const [tenantName, setTenantName] = useState("");
  const [tenantId, setTenantId] = useState("");
  const [budgetLimit, setBudgetLimit] = useState(50);

  // Step 2 state
  const [selectedBlueprint, setSelectedBlueprint] = useState(BLUEPRINTS[0]);
  const [agentName, setAgentName] = useState("");
  const [registering, setRegistering] = useState(false);

  // Step 3 state
  const [goal, setGoal] = useState("");
  const [running, setRunning] = useState(false);

  async function completeTenantStep(e: React.FormEvent) {
    e.preventDefault();
    const tid = tenantId.trim() || tenantName.trim().toLowerCase().replace(/\s+/g, "-");
    setResult((r) => ({ ...r, tenantId: tid }));
    setError(null);
    setStep("agent");
  }

  async function registerAgent(e: React.FormEvent) {
    e.preventDefault();
    setRegistering(true);
    setError(null);
    try {
      const name = agentName.trim() || `${selectedBlueprint.name} Agent`;
      const agent = await api.registerAgent({
        name,
        tenant_id: result.tenantId!,
        description: selectedBlueprint.desc,
        goal_types: selectedBlueprint.goals,
        skill_ids: selectedBlueprint.skills,
        capabilities: ALL_CAPS,
      });
      setResult((r) => ({ ...r, agentId: agent.agent_id, agentName: agent.name }));
      setStep("objective");
    } catch (e) {
      setError(String(e));
    } finally {
      setRegistering(false);
    }
  }

  async function runObjective(e: React.FormEvent) {
    e.preventDefault();
    if (!goal.trim()) return;
    setRunning(true);
    setError(null);
    try {
      const res = await api.runObjective({ goal: goal.trim(), priority: 7 });
      setResult((r) => ({ ...r, objectiveId: res.objective.id, goal: goal.trim(), status: res.objective.status }));
      setStep("done");
    } catch (e) {
      setError(String(e));
    } finally {
      setRunning(false);
    }
  }

  function reset() {
    setStep("tenant");
    setResult({});
    setError(null);
    setTenantName("");
    setTenantId("");
    setAgentName("");
    setGoal("");
  }

  const currentIdx = STEPS.findIndex((s) => s.key === step);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Onboarding</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          First-run setup: configure a tenant, register your first agent, run your first objective.
        </p>
      </div>

      {/* Progress bar */}
      <div style={{ display: "flex", gap: 0 }}>
        {STEPS.map((s, i) => {
          const done = i < currentIdx;
          const active = s.key === step;
          return (
            <div key={s.key} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", position: "relative" }}>
              {i > 0 && (
                <div style={{
                  position: "absolute", top: 14, right: "50%", left: "-50%",
                  height: 2,
                  background: done ? "var(--accent)" : "var(--border)",
                  zIndex: 0,
                }} />
              )}
              <div style={{
                width: 28, height: 28, borderRadius: "50%", zIndex: 1,
                display: "flex", alignItems: "center", justifyContent: "center",
                background: done ? "var(--accent)" : active ? "var(--accent)" : "var(--surface-2)",
                border: `2px solid ${done || active ? "var(--accent)" : "var(--border)"}`,
                color: done || active ? "#fff" : "var(--text-muted)",
                fontSize: 11, fontWeight: 700,
              }}>
                {done ? "✓" : s.icon}
              </div>
              <span style={{ marginTop: 5, fontSize: 11, color: active ? "var(--text)" : "var(--text-muted)", fontWeight: active ? 600 : 400 }}>
                {s.label}
              </span>
            </div>
          );
        })}
      </div>

      {error && (
        <div style={{ padding: "10px 14px", borderRadius: 8, border: "1px solid var(--red)", color: "var(--red)", fontSize: 13 }}>
          {error}
        </div>
      )}

      {/* Step 1: Tenant */}
      {step === "tenant" && (
        <Card title="Step 1 — Configure your tenant">
          <p style={{ fontSize: 13, color: "var(--text-muted)", marginBottom: 16 }}>
            Tenants are the top-level billing and isolation unit. Every agent, objective, and usage record belongs to a tenant.
          </p>
          <form onSubmit={completeTenantStep} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <Field label="Organisation name">
              <input
                value={tenantName}
                onChange={(e) => { setTenantName(e.target.value); if (!tenantId) setTenantId(e.target.value.toLowerCase().replace(/\s+/g, "-")); }}
                placeholder="e.g. Acme Corp"
                style={inputStyle}
                required
              />
            </Field>
            <Field label="Tenant ID (auto-generated from name)">
              <input
                value={tenantId}
                onChange={(e) => setTenantId(e.target.value)}
                placeholder="tenant-acme-corp"
                style={{ ...inputStyle, fontFamily: "monospace" }}
              />
              <p style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 3 }}>
                Used as the partition key for all records. Lowercase, hyphens only.
              </p>
            </Field>
            <Field label="Monthly budget limit (USD)">
              <input
                type="number"
                min={1}
                value={budgetLimit}
                onChange={(e) => setBudgetLimit(+e.target.value)}
                style={{ ...inputStyle, width: 120 }}
              />
            </Field>
            <button type="submit" style={primaryBtn}>Continue →</button>
          </form>
        </Card>
      )}

      {/* Step 2: First agent */}
      {step === "agent" && (
        <Card title="Step 2 — Register your first agent">
          <p style={{ fontSize: 13, color: "var(--text-muted)", marginBottom: 16 }}>
            Tenant: <code style={{ fontSize: 12 }}>{result.tenantId}</code>. Pick a blueprint — every agent ships with all 8 capabilities by default.
          </p>
          <form onSubmit={registerAgent} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <Field label="Blueprint">
              <div style={{ display: "flex", gap: 10 }}>
                {BLUEPRINTS.map((bp) => (
                  <button
                    key={bp.id}
                    type="button"
                    onClick={() => setSelectedBlueprint(bp)}
                    style={{
                      flex: 1, padding: "12px 10px", borderRadius: 8, textAlign: "left",
                      border: `2px solid ${selectedBlueprint.id === bp.id ? "var(--accent)" : "var(--border)"}`,
                      background: selectedBlueprint.id === bp.id ? "rgba(99,102,241,0.08)" : "var(--surface-2)",
                      cursor: "pointer",
                    }}
                  >
                    <div style={{ fontWeight: 600, fontSize: 13, color: selectedBlueprint.id === bp.id ? "var(--accent)" : "var(--text)" }}>{bp.name}</div>
                    <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 3, lineHeight: 1.4 }}>{bp.desc}</div>
                  </button>
                ))}
              </div>
            </Field>
            <Field label="Agent name (optional)">
              <input
                value={agentName}
                onChange={(e) => setAgentName(e.target.value)}
                placeholder={`${selectedBlueprint.name} Agent`}
                style={inputStyle}
              />
            </Field>
            <div style={{ padding: "10px 14px", borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--border)", fontSize: 12 }}>
              <div style={{ fontWeight: 600, marginBottom: 6, color: "var(--text-muted)", textTransform: "uppercase", fontSize: 10, letterSpacing: "0.06em" }}>
                What the DB will enforce on registration
              </div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
                {Object.keys(ALL_CAPS).map((c) => (
                  <span key={c} style={{ fontSize: 10, padding: "2px 7px", borderRadius: 4, background: "rgba(16,185,129,0.1)", color: "var(--green)", border: "1px solid var(--green)" }}>
                    {c} ✓
                  </span>
                ))}
              </div>
              <p style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 8 }}>
                DEFINE EVENT auto-seeds 3 memories (procedural + semantic + episodic) on creation.
              </p>
            </div>
            <button type="submit" disabled={registering} style={primaryBtn}>
              {registering ? "Registering…" : "Register agent →"}
            </button>
          </form>
        </Card>
      )}

      {/* Step 3: First objective */}
      {step === "objective" && (
        <Card title="Step 3 — Run your first objective">
          <div style={{ display: "flex", gap: 12, marginBottom: 16 }}>
            <div style={{ padding: "8px 12px", borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--border)", fontSize: 12 }}>
              <span style={{ color: "var(--text-muted)" }}>Tenant: </span>
              <code>{result.tenantId}</code>
            </div>
            <div style={{ padding: "8px 12px", borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--border)", fontSize: 12 }}>
              <span style={{ color: "var(--text-muted)" }}>Agent: </span>
              <code>{result.agentName}</code>
            </div>
          </div>
          <p style={{ fontSize: 13, color: "var(--text-muted)", marginBottom: 16 }}>
            An objective is a schema:Action submitted to the runtime. It gets decomposed into tasks, assigned to agents, and produces schema:CreativeWork artifacts.
          </p>
          <form onSubmit={runObjective} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <Field label="Goal">
              <textarea
                value={goal}
                onChange={(e) => setGoal(e.target.value)}
                rows={3}
                placeholder="e.g. Research the top 5 use cases for SurrealDB in enterprise AI applications"
                style={{ ...inputStyle, resize: "vertical" }}
                required
              />
            </Field>
            <button type="submit" disabled={running || !goal.trim()} style={primaryBtn}>
              {running ? "Running…" : "Run objective →"}
            </button>
          </form>
        </Card>
      )}

      {/* Step 4: Done */}
      {step === "done" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <Card title="You're set up">
            <p style={{ fontSize: 13, color: "var(--text-muted)", marginBottom: 16 }}>
              Your platform is live. Here's what was created:
            </p>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <SummaryRow icon="🏢" label="Tenant" value={result.tenantId!} />
              <SummaryRow icon="🤖" label="Agent" value={`${result.agentName} (${result.agentId})`} />
              <SummaryRow icon="🎯" label="Objective" value={result.goal!} />
              <SummaryRow icon="📊" label="Status">
                <StatusBadge status={result.status ?? "completed"} />
              </SummaryRow>
            </div>
          </Card>

          <Card title="What's next">
            <div style={{ display: "flex", flexDirection: "column", gap: 10, fontSize: 13 }}>
              {[
                { page: "/build",      label: "Agent Builder",  desc: "Build more agents from blueprints or from scratch" },
                { page: "/memory",     label: "Memory",         desc: "View the 3 auto-seeded memories for your agent" },
                { page: "/runtime",    label: "Runtime",        desc: "Watch live agent state via LIVE SELECT WebSocket" },
                { page: "/billing",    label: "Billing",        desc: "View cost breakdown by model and objective" },
                { page: "/objectives", label: "Objectives",     desc: "Submit more objectives and track results" },
              ].map((item) => (
                <a key={item.page} href={item.page} style={{ display: "flex", gap: 12, padding: "10px 12px", borderRadius: 8, border: "1px solid var(--border)", background: "var(--surface-2)", textDecoration: "none" }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 600, color: "var(--accent)", fontSize: 13 }}>{item.label}</div>
                    <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{item.desc}</div>
                  </div>
                  <span style={{ color: "var(--text-muted)", alignSelf: "center" }}>→</span>
                </a>
              ))}
            </div>
          </Card>

          <button onClick={reset} style={{ ...secondaryBtn, alignSelf: "flex-start" }}>
            Onboard another tenant
          </button>
        </div>
      )}
    </div>
  );
}

function SummaryRow({ icon, label, value, children }: { icon: string; label: string; value?: string; children?: React.ReactNode }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 0", borderBottom: "1px solid var(--border)", fontSize: 13 }}>
      <span style={{ fontSize: 16 }}>{icon}</span>
      <span style={{ color: "var(--text-muted)", minWidth: 70 }}>{label}</span>
      {value && <code style={{ fontSize: 12 }}>{value}</code>}
      {children}
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
      <label style={{ fontSize: 11, fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em" }}>{label}</label>
      {children}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: "100%", background: "var(--surface-2)", border: "1px solid var(--border)",
  borderRadius: 7, padding: "8px 12px", color: "var(--text)", fontSize: 14,
  outline: "none", boxSizing: "border-box",
};
const primaryBtn: React.CSSProperties = {
  alignSelf: "flex-start", padding: "9px 22px", borderRadius: 7, border: "none",
  background: "var(--accent)", color: "#fff", fontWeight: 600, fontSize: 14, cursor: "pointer",
};
const secondaryBtn: React.CSSProperties = {
  padding: "8px 16px", borderRadius: 7, border: "1px solid var(--border)",
  background: "var(--surface-2)", color: "var(--text)", fontSize: 13, cursor: "pointer",
};
