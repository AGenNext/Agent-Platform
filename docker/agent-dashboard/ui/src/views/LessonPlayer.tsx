import { useMemo, useState } from 'react'
import type { LearningPath } from '../api'
import { Award, Check, ChevronLeft, CircleDot, Play, RotateCcw, Terminal } from 'lucide-react'

type Lesson = {
  intro: string
  points: string[]
  filename: string
  code: string
  output: string[]
  skills: string[]
}

// OpenLMX-style: every module is a hands-on lesson — read, edit, run, earn competency.
function lessonFor(moduleTitle: string): Lesson {
  const T = moduleTitle.toLowerCase()
  if (T.includes('space') || T.includes('objective')) return {
    intro: 'A Space is a governed workspace; an Objective is a goal you hand to agents. You author both as data, then runs attach to them.',
    points: ['Spaces own runs, artifacts and trust', 'Objectives carry a type + payload', 'Everything is a record in SurrealDB'],
    filename: 'create_objective.surql', skills: ['Spaces', 'Objectives'],
    code: `CREATE objective SET\n  title  = "Compare Q3 vendors",\n  type   = "generation",\n  space  = space:vendor_intel,\n  status = "pending";`,
    output: ['objective:8f2a created', 'status = pending', 'attached to space:vendor_intel'],
  }
  if (T.includes('composer')) return {
    intro: 'The Composer turns a plain-language objective into a typed agent pipeline. You describe the goal; it generates a SurrealQL function.',
    points: ['Chat → generated pipeline', 'Agents propose, the DB records', 'Edit the code, then Apply'],
    filename: 'pipeline.surql', skills: ['Composer', 'AgentQL'],
    code: `DEFINE FUNCTION fn::run($obj: record<objective>) {\n  LET $plan = fn::start_agent($obj, "planner");\n  LET $draft = fn::handoff($plan, "writer");\n  RETURN $draft.artifact;\n};`,
    output: ['function fn::run defined', 'agents: planner → writer', 'returns: artifact ref'],
  }
  if (T.includes('preview') || T.includes('deploy')) return {
    intro: 'Preview dry-runs the pipeline as an agent step flow. Deploy publishes it as a callable endpoint once gates pass.',
    points: ['Preview shows each handoff', 'Deploy needs passing gates', 'Endpoint is versioned'],
    filename: 'deploy.surql', skills: ['Deploy', 'Endpoints'],
    code: `LET $check = fn::preview(fn::run, objective:8f2a);\nIF $check.gates_passed {\n  RETURN fn::deploy(fn::run, { name: "vendor-pipeline" });\n};`,
    output: ['preview: 5 steps ok', 'gates_passed = true', 'POST /agents/vendor-pipeline · v1'],
  }
  if (T.includes('policy') || T.includes('gate')) return {
    intro: 'Policy gates run before any agent acts. A blocked policy throws and the pipeline never executes — governance by construction.',
    points: ['Gate evaluates before agents', 'Deny = throw + audit', 'Policies are reusable records'],
    filename: 'policy_gate.surql', skills: ['Governance', 'Policy'],
    code: `LET $p = fn::evaluate_policy($obj, "AGX-RUNTIME-DEFAULT");\nIF $p.effect != "allow" {\n  THROW "blocked by governance policy";\n};`,
    output: ['policy AGX-RUNTIME-DEFAULT', 'effect = allow', 'gate passed'],
  }
  if (T.includes('clear') || T.includes('eval') || T.includes('dimension') || T.includes('threshold')) return {
    intro: 'CLEAR scores an artifact across dimensions and gates on a composite threshold. Below the bar, publish is blocked.',
    points: ['Composite of weighted dimensions', 'Gate at composite ≥ 0.70', 'Rationale stored with the score'],
    filename: 'eval.surql', skills: ['Evaluation', 'CLEAR'],
    code: `LET $eval = fn::record_evaluation($artifact, "CLEAR");\nIF $eval.composite_score < 0.7 {\n  THROW "failed CLEAR eval gate";\n};`,
    output: ['composite_score = 0.86', 'passed = true', 'threshold = 0.70'],
  }
  if (T.includes('trust')) return {
    intro: 'Trust accumulates evidence over an artifact’s life. Scores feed the publish gate and surface across the workspace.',
    points: ['Evidence-weighted score', 'Updates on each evaluation', 'Visible on every artifact'],
    filename: 'trust.surql', skills: ['Trust'],
    code: `LET $trust = fn::update_trust($artifact);\nRETURN { score: $trust.score, evidence: $trust.evidence_count };`,
    output: ['score = 0.82', 'evidence_count = 7', 'trust updated'],
  }
  if (T.includes('route') || T.includes('fallback') || T.includes('cost')) return {
    intro: 'The AI Gateway routes requests across models with fallbacks, then tracks cost and latency per route.',
    points: ['Primary + fallback routes', 'Share-based traffic split', 'Cost & p95 per model'],
    filename: 'router.surql', skills: ['Routing', 'Cost'],
    code: `DEFINE ROUTE default\n  PRIMARY  claude-sonnet-4.6\n  FALLBACK claude-opus-4.8\n  BUDGET   "$500/day";`,
    output: ['route default defined', 'primary → sonnet-4.6', 'fallback → opus-4.8'],
  }
  return {
    intro: `Hands-on lesson: ${moduleTitle}. Read the snippet, tweak it, and run to see how the platform responds.`,
    points: ['Edit the code on the right', 'Run to see output', 'Mark complete to continue'],
    filename: 'lesson.surql', skills: [moduleTitle],
    code: `-- ${moduleTitle}\nRETURN fn::demo("${moduleTitle}");`,
    output: [`ran: ${moduleTitle}`, 'ok'],
  }
}

export function LessonPlayer({ path, onBack }: { path: LearningPath; onBack: () => void }) {
  const [active, setActive] = useState(() => {
    const i = path.modules.findIndex(m => !m.done)
    return i === -1 ? 0 : i
  })
  const [done, setDone] = useState<Set<number>>(() =>
    new Set(path.modules.map((m, i) => (m.done ? i : -1)).filter(i => i >= 0)))

  const module = path.modules[active]
  const lesson = useMemo(() => lessonFor(module.title), [module.title])
  const [code, setCode] = useState(lesson.code)
  const [ran, setRan] = useState(false)

  const select = (i: number) => { setActive(i); setCode(lessonFor(path.modules[i].title).code); setRan(false) }
  const complete = () => {
    setDone(d => new Set(d).add(active))
    if (active < path.modules.length - 1) select(active + 1)
  }

  const allDone = done.size === path.modules.length
  const progress = done.size / path.modules.length

  return (
    <div className="space-y-4">
      <button onClick={onBack} className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-ink transition-colors">
        <ChevronLeft size={16} /> Learning Paths
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-[260px_1fr] gap-4">
        {/* Outline */}
        <aside className="rounded-xl border border-line bg-surface/60 p-4 h-max">
          <div className="text-sm font-semibold text-ink leading-snug">{path.title}</div>
          <div className="mt-2 flex items-center justify-between text-[11px] text-faint">
            <span>{done.size} / {path.modules.length} done</span>
            <span className="nums">{Math.round(progress * 100)}%</span>
          </div>
          <div className="mt-1.5 h-1.5 rounded-full bg-line overflow-hidden">
            <div className="h-full rounded-full bg-gradient-to-r from-accent-strong to-accent transition-all" style={{ width: `${Math.round(progress * 100)}%` }} />
          </div>
          <ul className="mt-4 space-y-1">
            {path.modules.map((m, i) => (
              <li key={m.title}>
                <button onClick={() => select(i)}
                  className={`w-full flex items-center gap-2 px-2.5 py-2 rounded-lg text-xs text-left transition-colors ${
                    i === active ? 'bg-raised text-ink ring-1 ring-line-strong' : 'text-muted hover:bg-raised/50 hover:text-ink'}`}>
                  {done.has(i)
                    ? <Check size={14} className="text-ok shrink-0" />
                    : i === active ? <CircleDot size={14} className="text-accent shrink-0" /> : <span className="w-3.5 h-3.5 rounded-full border border-line shrink-0" />}
                  <span className="truncate">{m.title}</span>
                </button>
              </li>
            ))}
          </ul>
        </aside>

        {/* Lesson */}
        <div className="space-y-4">
          {allDone && (
            <div className="glow-border bg-surface/70 p-5 flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-accent/15 text-accent ring-1 ring-accent/30 grid place-items-center shrink-0">
                <Award size={24} />
              </div>
              <div>
                <div className="text-sm font-semibold text-ink">Credential earned · {path.title}</div>
                <p className="text-xs text-faint mt-0.5">Competency verified and added to your skill passport. {path.level} track complete.</p>
              </div>
            </div>
          )}

          <div className="rounded-xl border border-line bg-surface/60 p-5">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-[11px] font-medium text-faint">Module {active + 1}</span>
              {lesson.skills.map(s => (
                <span key={s} className="rounded-full bg-accent/10 text-accent ring-1 ring-accent/20 px-2 py-0.5 text-[10px] font-medium">{s}</span>
              ))}
            </div>
            <h2 className="text-lg font-semibold text-ink tracking-tight">{module.title}</h2>
            <p className="text-sm text-muted mt-2 leading-relaxed">{lesson.intro}</p>
            <ul className="mt-3 space-y-1.5">
              {lesson.points.map(p => (
                <li key={p} className="flex items-start gap-2 text-sm text-muted">
                  <span className="mt-1.5 w-1 h-1 rounded-full bg-accent shrink-0" />{p}
                </li>
              ))}
            </ul>
          </div>

          {/* Interactive code */}
          <div className="glow-border bg-[#0b0f17] flex flex-col overflow-hidden">
            <div className="px-4 py-2.5 border-b border-line flex items-center justify-between">
              <span className="text-xs text-muted font-mono">{lesson.filename}</span>
              <div className="flex items-center gap-1.5">
                <button onClick={() => { setCode(lesson.code); setRan(false) }} className="inline-flex items-center gap-1 text-[11px] text-muted hover:text-ink rounded-md px-2 py-1 hover:bg-raised transition-colors"><RotateCcw size={12} /> Reset</button>
                <button onClick={() => setRan(true)} className="inline-flex items-center gap-1 text-[11px] text-white rounded-md px-2 py-1 bg-accent-strong hover:bg-accent transition-colors"><Play size={12} /> Run</button>
              </div>
            </div>
            <textarea
              value={code}
              onChange={e => { setCode(e.target.value); setRan(false) }}
              spellCheck={false}
              rows={Math.max(5, code.split('\n').length)}
              className="bg-transparent text-[12.5px] leading-relaxed font-mono text-ink p-4 focus:outline-none resize-none w-full"
            />
            <div className="border-t border-line px-4 py-3 bg-black/30">
              <div className="flex items-center gap-1.5 text-[11px] text-faint mb-1.5"><Terminal size={12} /> Output</div>
              {ran ? (
                <pre className="text-[12px] font-mono text-ok/90 leading-relaxed">{lesson.output.map(l => `→ ${l}`).join('\n')}</pre>
              ) : (
                <div className="text-[12px] font-mono text-faint">Press Run to execute.</div>
              )}
            </div>
          </div>

          <div className="flex items-center justify-end gap-2">
            {done.has(active)
              ? <span className="inline-flex items-center gap-1.5 text-xs text-ok"><Check size={14} /> Completed</span>
              : null}
            <button onClick={complete} className="rounded-lg bg-accent-strong hover:bg-accent text-white text-sm font-medium px-4 py-2 transition-colors">
              {active < path.modules.length - 1 ? 'Mark complete & continue' : 'Mark complete'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
