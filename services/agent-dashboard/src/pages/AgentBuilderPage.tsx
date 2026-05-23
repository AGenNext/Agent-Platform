import { useEffect, useRef, useState } from "react";
import { api, type AgentRecord } from "../api/client";
import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";

// ── Hardcoded fallback data (mirrors blueprint.surql + rules.surql) ───────────

const FALLBACK_BLUEPRINTS: Blueprint[] = [
  { blueprint_id: "agent.orchestrator", name: "Orchestrator", description: "Decomposes objectives, assigns tasks, synthesises results.", goal_types: ["decompose_objective", "assign_tasks", "synthesize_results"], skill_ids: ["skill.decompose", "skill.assign", "skill.synthesize"], cost_limit_usd: 2.0 },
  { blueprint_id: "agent.researcher",   name: "Researcher",   description: "Discovers, retrieves and synthesises information from sources.", goal_types: ["web_research", "document_retrieval", "source_synthesis"], skill_ids: ["skill.search", "skill.scrape", "skill.summarize", "skill.cite"], cost_limit_usd: 1.0 },
  { blueprint_id: "agent.writer",       name: "Writer",       description: "Generates written artifacts from source material.", goal_types: ["write_blog", "write_product_doc", "write_rfp"], skill_ids: ["skill.write", "skill.structure", "skill.format", "skill.brand_align"], cost_limit_usd: 1.5 },
  { blueprint_id: "agent.evaluator",    name: "Evaluator",    description: "Evaluates artifact quality using CLEAR scoring.", goal_types: ["evaluate_artifact", "score_trust", "flag_hallucination"], skill_ids: ["skill.clear_score", "skill.fact_check", "skill.trust_evaluate"], cost_limit_usd: 0.5 },
  { blueprint_id: "agent.router",       name: "Model Router", description: "Routes tasks to optimal model/provider under cost + policy constraints.", goal_types: ["route_model", "enforce_policy", "attribute_cost"], skill_ids: ["skill.model_select", "skill.cost_estimate", "skill.policy_check"], cost_limit_usd: 0.1 },
  { blueprint_id: "agent.knowledge",    name: "Knowledge",    description: "Enterprise RAG — semantic search, graph traversal.", goal_types: ["rag_query", "semantic_search", "graph_traversal"], skill_ids: ["skill.rag", "skill.embed", "skill.graph_query", "skill.fts"], cost_limit_usd: 0.5 },
  { blueprint_id: "agent.trust",        name: "Trust",        description: "Builds provenance chains, validates evidence, assigns trust scores.", goal_types: ["build_provenance", "validate_evidence", "assign_trust_score"], skill_ids: ["skill.provenance", "skill.evidence_check", "skill.trust_score"], cost_limit_usd: 0.3 },
  { blueprint_id: "agent.monitor",      name: "Monitor",      description: "Monitors platform health, emits health checks, alerts on degraded agents.", goal_types: ["health_check", "alert", "diagnose"], skill_ids: ["skill.health_ping", "skill.diagnose", "skill.alert"], cost_limit_usd: 0.1 },
];

const FALLBACK_SKILLS: Skill[] = [
  { skill_id: "skill.decompose",      name: "Decompose Objective",  category: "orchestration" },
  { skill_id: "skill.assign",         name: "Assign Task",          category: "orchestration" },
  { skill_id: "skill.synthesize",     name: "Synthesize Results",   category: "orchestration" },
  { skill_id: "skill.search",         name: "Web Search",           category: "research" },
  { skill_id: "skill.scrape",         name: "Document Scrape",      category: "research" },
  { skill_id: "skill.summarize",      name: "Summarize",            category: "research" },
  { skill_id: "skill.cite",           name: "Generate Citations",   category: "research" },
  { skill_id: "skill.write",          name: "Write Artifact",       category: "writing" },
  { skill_id: "skill.structure",      name: "Structure Content",    category: "writing" },
  { skill_id: "skill.format",         name: "Format Output",        category: "writing" },
  { skill_id: "skill.brand_align",    name: "Brand Alignment",      category: "writing" },
  { skill_id: "skill.clear_score",    name: "CLEAR Evaluation",     category: "evaluation" },
  { skill_id: "skill.fact_check",     name: "Fact Check",           category: "evaluation" },
  { skill_id: "skill.trust_evaluate", name: "Trust Evaluation",     category: "evaluation" },
  { skill_id: "skill.model_select",   name: "Model Selection",      category: "routing" },
  { skill_id: "skill.cost_estimate",  name: "Cost Estimation",      category: "routing" },
  { skill_id: "skill.policy_check",   name: "Policy Check",         category: "routing" },
  { skill_id: "skill.rag",            name: "RAG Query",            category: "knowledge" },
  { skill_id: "skill.embed",          name: "Generate Embedding",   category: "knowledge" },
  { skill_id: "skill.graph_query",    name: "Graph Traversal",      category: "knowledge" },
  { skill_id: "skill.fts",            name: "Full-Text Search",     category: "knowledge" },
  { skill_id: "skill.provenance",     name: "Build Provenance",     category: "trust" },
  { skill_id: "skill.evidence_check", name: "Validate Evidence",    category: "trust" },
  { skill_id: "skill.trust_score",    name: "Assign Trust Score",   category: "trust" },
  { skill_id: "skill.health_ping",    name: "Health Ping",          category: "monitoring" },
  { skill_id: "skill.diagnose",       name: "Diagnose Failure",     category: "monitoring" },
  { skill_id: "skill.alert",          name: "Emit Alert",           category: "monitoring" },
];

const REQUIRED_CAPS = ["analytics", "billing", "health", "tracing", "auth", "artifacts", "skills", "trust"];

// ── Types ─────────────────────────────────────────────────────────────────────

interface Blueprint {
  blueprint_id: string;
  name: string;
  description: string;
  goal_types: string[];
  skill_ids: string[];
  cost_limit_usd: number;
}

interface Skill {
  skill_id: string;
  name: string;
  category: string;
}

type Step = "blueprint" | "name" | "tenant" | "description" | "goals" | "skills" | "cost" | "review" | "done";

interface Message {
  role: "bot" | "user";
  content: string;
  ui?: "blueprints" | "skills";
}

interface AgentDraft {
  name: string;
  tenant_id: string;
  description: string;
  goal_types: string[];
  skill_ids: string[];
  cost_limit_usd: number;
  capabilities: Record<string, boolean>;
}

const emptyDraft = (): AgentDraft => ({
  name: "",
  tenant_id: "tenant-default",
  description: "",
  goal_types: [],
  skill_ids: [],
  cost_limit_usd: 1.0,
  capabilities: Object.fromEntries(REQUIRED_CAPS.map((c) => [c, true])),
});

// ── Component ─────────────────────────────────────────────────────────────────

export function AgentBuilderPage() {
  const [blueprints, setBlueprints] = useState<Blueprint[]>(FALLBACK_BLUEPRINTS);
  const [skills, setSkills] = useState<Skill[]>(FALLBACK_SKILLS);
  const [messages, setMessages] = useState<Message[]>([
    { role: "bot", content: "Welcome to Agent Builder. Start from a platform blueprint or build from scratch:", ui: "blueprints" },
  ]);
  const [step, setStep] = useState<Step>("blueprint");
  const [input, setInput] = useState("");
  const [draft, setDraft] = useState<AgentDraft>(emptyDraft());
  const [selectedSkills, setSelectedSkills] = useState<Set<string>>(new Set());
  const [registering, setRegistering] = useState(false);
  const [registered, setRegistered] = useState<AgentRecord | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Try to fetch live blueprints/skills; fall back to hardcoded
    api.listBlueprints().then(setBlueprints).catch(() => {});
    api.listSkills().then(setSkills).catch(() => {});
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  function addBot(content: string, ui?: Message["ui"]) {
    setMessages((m) => [...m, { role: "bot", content, ui }]);
  }
  function addUser(content: string) {
    setMessages((m) => [...m, { role: "user", content }]);
  }

  function selectBlueprint(bp: Blueprint) {
    const updated: AgentDraft = {
      ...emptyDraft(),
      description: bp.description,
      goal_types: bp.goal_types,
      skill_ids: bp.skill_ids,
      cost_limit_usd: bp.cost_limit_usd,
    };
    setDraft(updated);
    setSelectedSkills(new Set(bp.skill_ids));
    addUser(`Blueprint: ${bp.name}`);
    addBot(`Loaded **${bp.name}** blueprint — ${bp.description}\n\nWhat do you want to name this agent?`);
    setStep("name");
  }

  function startFromScratch() {
    addUser("Build from scratch");
    addBot("What do you want to name this agent?");
    setStep("name");
  }

  function handleSend() {
    const val = input.trim();
    if (!val) return;
    setInput("");
    addUser(val);
    advance(val);
  }

  function advance(val: string) {
    switch (step) {
      case "name": {
        setDraft((d) => ({ ...d, name: val }));
        addBot(`Got it — **${val}**.\n\nWhat tenant should this agent belong to? (default: tenant-default)`);
        setStep("tenant");
        break;
      }
      case "tenant": {
        const tenant = val || "tenant-default";
        setDraft((d) => ({ ...d, tenant_id: tenant }));
        if (draft.description) {
          addBot(`Tenant set to **${tenant}**.\n\nCurrent description: "${draft.description}"\n\nType a new description or press Enter to keep it.`);
        } else {
          addBot(`Tenant set to **${tenant}**.\n\nDescribe what this agent does:`);
        }
        setStep("description");
        break;
      }
      case "description": {
        const desc = val || draft.description;
        setDraft((d) => ({ ...d, description: desc }));
        if (draft.goal_types.length) {
          addBot(`Description saved.\n\nCurrent goal types: ${draft.goal_types.join(", ")}\n\nType new goal types (comma-separated) or press Enter to keep them:`);
        } else {
          addBot(`What goal types will this agent handle? Enter comma-separated values, e.g.:\n_research, summarization, web_search_`);
        }
        setStep("goals");
        break;
      }
      case "goals": {
        const goals = val
          ? val.split(",").map((g) => g.trim()).filter(Boolean)
          : draft.goal_types;
        setDraft((d) => ({ ...d, goal_types: goals }));
        addBot(`Goal types set: ${goals.join(", ")}.\n\nNow pick skills for this agent:`, "skills");
        setStep("skills");
        break;
      }
      case "cost": {
        const cost = parseFloat(val);
        setDraft((d) => ({ ...d, cost_limit_usd: isNaN(cost) ? d.cost_limit_usd : cost }));
        addBot("Review your agent config on the right. Hit **Register** when ready.");
        setStep("review");
        break;
      }
    }
  }

  function confirmSkills() {
    const ids = Array.from(selectedSkills);
    setDraft((d) => ({ ...d, skill_ids: ids }));
    addBot(`Skills locked in: ${ids.map((id) => id.replace("skill.", "")).join(", ")}.\n\nCost limit in USD (default: ${draft.cost_limit_usd}):`);
    setStep("cost");
  }

  async function register() {
    setRegistering(true);
    try {
      const agent = await api.registerAgent({
        name: draft.name,
        tenant_id: draft.tenant_id,
        description: draft.description || undefined,
        goal_types: draft.goal_types,
        skill_ids: draft.skill_ids,
        capabilities: draft.capabilities,
      });
      setRegistered(agent);
      addBot(`Agent **${agent.name}** registered successfully!\n\nID: \`${agent.agent_id}\`\nStatus: ${agent.status}\n\nThe DB has verified all 8 capabilities and auto-seeded 3 memories via DEFINE EVENT.`);
      setStep("done");
    } catch (e) {
      addBot(`Registration failed: ${String(e)}`);
    } finally {
      setRegistering(false);
    }
  }

  function reset() {
    setDraft(emptyDraft());
    setSelectedSkills(new Set());
    setRegistered(null);
    setStep("blueprint");
    setMessages([{ role: "bot", content: "Build another agent? Start from a blueprint or describe from scratch:", ui: "blueprints" }]);
  }

  const groupedSkills = skills.reduce<Record<string, Skill[]>>((acc, s) => {
    (acc[s.category] ??= []).push(s);
    return acc;
  }, {});

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Agent Builder</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          Chat-driven agent configuration. Every agent ships with all 8 capabilities — the DB enforces this.
        </p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 360px", gap: 16, alignItems: "start" }}>

        {/* ── Chat panel ───────────────────────────────── */}
        <Card title="Build">
          <div
            style={{
              height: 460,
              overflowY: "auto",
              display: "flex",
              flexDirection: "column",
              gap: 12,
              paddingBottom: 8,
            }}
          >
            {messages.map((msg, i) => (
              <div key={i}>
                <Bubble msg={msg} />
                {msg.ui === "blueprints" && (
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 10, paddingLeft: 8 }}>
                    {blueprints.map((bp) => (
                      <button
                        key={bp.blueprint_id}
                        onClick={() => selectBlueprint(bp)}
                        disabled={step !== "blueprint"}
                        style={chipBtnStyle(step === "blueprint")}
                        title={bp.description}
                      >
                        {bp.name}
                      </button>
                    ))}
                    <button
                      onClick={startFromScratch}
                      disabled={step !== "blueprint"}
                      style={{ ...chipBtnStyle(step === "blueprint"), color: "var(--text-muted)" }}
                    >
                      From scratch
                    </button>
                  </div>
                )}
                {msg.ui === "skills" && (
                  <div style={{ marginTop: 10, paddingLeft: 8 }}>
                    {Object.entries(groupedSkills).map(([cat, catSkills]) => (
                      <div key={cat} style={{ marginBottom: 10 }}>
                        <div style={{ fontSize: 10, color: "var(--text-muted)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 5 }}>
                          {cat}
                        </div>
                        <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
                          {catSkills.map((s) => {
                            const on = selectedSkills.has(s.skill_id);
                            return (
                              <button
                                key={s.skill_id}
                                onClick={() => {
                                  if (step !== "skills") return;
                                  setSelectedSkills((prev) => {
                                    const next = new Set(prev);
                                    on ? next.delete(s.skill_id) : next.add(s.skill_id);
                                    return next;
                                  });
                                }}
                                style={{
                                  fontSize: 11,
                                  padding: "3px 9px",
                                  borderRadius: 5,
                                  border: `1px solid ${on ? "var(--accent)" : "var(--border)"}`,
                                  background: on ? "rgba(99,102,241,0.12)" : "var(--surface-2)",
                                  color: on ? "var(--accent)" : "var(--text-muted)",
                                  cursor: step === "skills" ? "pointer" : "default",
                                }}
                              >
                                {s.name}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    ))}
                    {step === "skills" && (
                      <button
                        onClick={confirmSkills}
                        style={{
                          marginTop: 8,
                          padding: "7px 16px",
                          borderRadius: 7,
                          border: "none",
                          background: "var(--accent)",
                          color: "#fff",
                          fontWeight: 600,
                          fontSize: 13,
                          cursor: "pointer",
                        }}
                      >
                        Confirm skills ({selectedSkills.size})
                      </button>
                    )}
                  </div>
                )}
              </div>
            ))}
            <div ref={bottomRef} />
          </div>

          {/* Input bar */}
          {!["blueprint", "skills", "done"].includes(step) && (
            <div style={{ display: "flex", gap: 8, marginTop: 10, borderTop: "1px solid var(--border)", paddingTop: 10 }}>
              <input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSend()}
                placeholder={stepPlaceholder(step)}
                style={{
                  flex: 1,
                  background: "var(--surface-2)",
                  border: "1px solid var(--border)",
                  borderRadius: 7,
                  padding: "8px 12px",
                  color: "var(--text)",
                  fontSize: 14,
                  outline: "none",
                }}
                autoFocus
              />
              <button
                onClick={handleSend}
                style={{ padding: "8px 16px", borderRadius: 7, border: "none", background: "var(--accent)", color: "#fff", fontWeight: 600, cursor: "pointer" }}
              >
                Send
              </button>
            </div>
          )}

          {step === "review" && (
            <div style={{ display: "flex", gap: 10, marginTop: 10, borderTop: "1px solid var(--border)", paddingTop: 10 }}>
              <button
                onClick={register}
                disabled={registering}
                style={{ flex: 1, padding: "10px", borderRadius: 7, border: "none", background: "var(--green)", color: "#fff", fontWeight: 700, fontSize: 15, cursor: registering ? "not-allowed" : "pointer", opacity: registering ? 0.6 : 1 }}
              >
                {registering ? "Registering…" : "Register Agent"}
              </button>
              <button
                onClick={reset}
                style={{ padding: "10px 16px", borderRadius: 7, border: "1px solid var(--border)", background: "transparent", color: "var(--text-muted)", cursor: "pointer" }}
              >
                Reset
              </button>
            </div>
          )}

          {step === "done" && (
            <button
              onClick={reset}
              style={{ marginTop: 10, width: "100%", padding: "10px", borderRadius: 7, border: "1px solid var(--border)", background: "var(--surface-2)", color: "var(--text)", fontWeight: 600, cursor: "pointer" }}
            >
              Build another agent
            </button>
          )}
        </Card>

        {/* ── Live preview ─────────────────────────────── */}
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <Card title="Agent Preview">
            <div style={{ display: "flex", flexDirection: "column", gap: 8, fontSize: 13 }}>
              <PreviewRow label="name"       value={draft.name || "—"} />
              <PreviewRow label="tenant_id"  value={draft.tenant_id} />
              <PreviewRow label="description" value={draft.description || "—"} mono={false} />
              <PreviewRow label="cost_limit" value={`$${draft.cost_limit_usd.toFixed(2)} USD`} />
              {draft.goal_types.length > 0 && (
                <div>
                  <span style={{ color: "var(--text-muted)" }}>goal_types</span>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 4, marginTop: 4 }}>
                    {draft.goal_types.map((g) => (
                      <span key={g} style={tagStyle}>{g}</span>
                    ))}
                  </div>
                </div>
              )}
              {draft.skill_ids.length > 0 && (
                <div>
                  <span style={{ color: "var(--text-muted)" }}>skills</span>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 4, marginTop: 4 }}>
                    {draft.skill_ids.map((s) => (
                      <span key={s} style={{ ...tagStyle, color: "var(--accent)" }}>{s.replace("skill.", "")}</span>
                    ))}
                  </div>
                </div>
              )}
              <div>
                <span style={{ color: "var(--text-muted)" }}>capabilities</span>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 4, marginTop: 4 }}>
                  {REQUIRED_CAPS.map((c) => (
                    <span key={c} style={{ ...tagStyle, color: "var(--green)", borderColor: "var(--green)" }}>{c}</span>
                  ))}
                </div>
              </div>
            </div>
          </Card>

          {registered && (
            <Card title="Registered">
              <div style={{ display: "flex", flexDirection: "column", gap: 6, fontSize: 12 }}>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: "var(--text-muted)" }}>status</span>
                  <StatusBadge status={registered.status} />
                </div>
                <PreviewRow label="agent_id" value={registered.agent_id} />
                <PreviewRow label="version"  value={registered.version} />
                <p style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 4 }}>
                  3 memories auto-seeded (procedural + semantic + episodic) via DEFINE EVENT.
                </p>
              </div>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Sub-components ─────────────────────────────────────────────────────────────

function Bubble({ msg }: { msg: Message }) {
  const isBot = msg.role === "bot";
  return (
    <div style={{ display: "flex", justifyContent: isBot ? "flex-start" : "flex-end" }}>
      <div
        style={{
          maxWidth: "85%",
          padding: "9px 13px",
          borderRadius: isBot ? "4px 12px 12px 12px" : "12px 4px 12px 12px",
          background: isBot ? "var(--surface-2)" : "var(--accent)",
          color: isBot ? "var(--text)" : "#fff",
          fontSize: 13,
          lineHeight: 1.5,
          whiteSpace: "pre-wrap",
          border: isBot ? "1px solid var(--border)" : "none",
        }}
      >
        {msg.content.split("**").map((part, i) =>
          i % 2 === 1 ? <strong key={i}>{part}</strong> : part
        )}
      </div>
    </div>
  );
}

function PreviewRow({ label, value, mono = true }: { label: string; value: string; mono?: boolean }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 8, padding: "4px 0", borderBottom: "1px solid var(--border)" }}>
      <span style={{ color: "var(--text-muted)", flexShrink: 0 }}>{label}</span>
      <span style={{ fontFamily: mono ? "monospace" : "inherit", fontSize: 12, textAlign: "right", wordBreak: "break-all" }}>{value}</span>
    </div>
  );
}

function stepPlaceholder(step: Step): string {
  switch (step) {
    case "name":        return "Agent name…";
    case "tenant":      return "Tenant ID (press Enter for default)…";
    case "description": return "Describe the agent… (or Enter to keep)";
    case "goals":       return "research, summarization, … (or Enter to keep)";
    case "cost":        return "Cost limit in USD (e.g. 1.0)…";
    default: return "Type a message…";
  }
}

function chipBtnStyle(active: boolean): React.CSSProperties {
  return {
    fontSize: 12,
    padding: "5px 12px",
    borderRadius: 20,
    border: "1px solid var(--border)",
    background: "var(--surface-2)",
    color: "var(--text)",
    cursor: active ? "pointer" : "default",
    opacity: active ? 1 : 0.5,
    fontWeight: 500,
  };
}

const tagStyle: React.CSSProperties = {
  fontSize: 10,
  padding: "2px 7px",
  borderRadius: 4,
  background: "var(--bg)",
  color: "var(--text-muted)",
  border: "1px solid var(--border)",
};
