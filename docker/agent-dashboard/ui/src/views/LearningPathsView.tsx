import { useEffect, useState } from 'react'
import { api, type LearningPath } from '../api'
import { LessonPlayer } from './LessonPlayer'
import { CheckCircle2, Circle, Clock, ExternalLink, GraduationCap, Users } from 'lucide-react'

const LEVEL_TONE: Record<LearningPath['level'], string> = {
  Beginner: 'text-ok bg-ok/10 ring-ok/20',
  Intermediate: 'text-info bg-info/10 ring-info/20',
  Advanced: 'text-accent bg-accent/10 ring-accent/20',
}

// Canonical course catalog shipped with the platform (open-lmx-style format).
// Authored from the platform's own stack + referenced open-lmx courses.
// Used as a fallback when GET /learning/paths is empty.
const CANONICAL: LearningPath[] = [
  {
    id: 'agent-platform-foundations',
    title: 'Building Governed Agents on the Agent Platform',
    description: 'Everything used to build the platform — from a plain-language objective to a governed, evaluated, deployed agent.',
    level: 'Intermediate', duration_min: 90, enrolled: 0, progress: 0,
    modules: [
      { title: 'Spaces & objectives', done: false },
      { title: 'Composer basics', done: false },
      { title: 'Policy gates', done: false },
      { title: 'CLEAR eval', done: false },
      { title: 'Trust scoring', done: false },
      { title: 'Preview & deploy', done: false },
      { title: 'Model routes', done: false },
    ],
  },
  {
    id: 'governance-guardrails',
    title: 'Governance & Guardrails',
    description: 'Add policy gates, CLEAR evaluation, and trust scoring so agents ship safely.',
    level: 'Intermediate', duration_min: 50, enrolled: 0, progress: 0,
    modules: [
      { title: 'Policy gates', done: false },
      { title: 'CLEAR eval', done: false },
      { title: 'Trust scoring', done: false },
      { title: 'Failure handling', done: false },
    ],
  },
  {
    id: 'routing-cost',
    title: 'Routing & Cost Control',
    description: 'Use the AI Gateway to route models, set fallbacks, and watch spend.',
    level: 'Intermediate', duration_min: 40, enrolled: 0, progress: 0,
    modules: [
      { title: 'Model routes', done: false },
      { title: 'Fallback policy', done: false },
      { title: 'Cost dashboards', done: false },
    ],
  },
  {
    id: 'langgraph-nextjs',
    title: 'LangGraph + Next.js',
    description: 'Code-first autonomous AI systems with the LangGraph Deep Agent Framework alongside Next.js.',
    level: 'Advanced', duration_min: 2400, enrolled: 0, progress: 0,
    source: 'open-lmx', href: 'https://github.com/open-lmx/courses',
    modules: [],
  },
  {
    id: 'multi-tenant-saas',
    title: 'Building Multi-Tenant Enterprise SaaS',
    description: 'Production SaaS foundation with Next.js, SurrealDB, Auth, RBAC, SSO, Billing, and Audit Logs.',
    level: 'Advanced', duration_min: 60, enrolled: 0, progress: 0,
    source: 'open-lmx', href: 'https://github.com/open-lmx/courses',
    modules: [],
  },
]

export function LearningPathsView() {
  const [paths, setPaths] = useState<LearningPath[]>([])
  const [loading, setLoading] = useState(true)
  const [open, setOpen] = useState<LearningPath | null>(null)

  useEffect(() => {
    api.learningPaths()
      .then(p => setPaths(p.length ? p : CANONICAL))
      .catch(() => setPaths(CANONICAL))
      .finally(() => setLoading(false))
  }, [])

  if (open) return <LessonPlayer path={open} onBack={() => setOpen(null)} />

  return (
    <div className="space-y-4">
      <div className="rounded-xl border border-line bg-gradient-to-br from-accent/10 via-surface/40 to-surface/40 p-5 flex items-center gap-4">
        <div className="w-11 h-11 rounded-xl bg-accent/15 text-accent ring-1 ring-accent/25 grid place-items-center shrink-0">
          <GraduationCap size={22} />
        </div>
        <div>
          <div className="text-sm font-semibold text-ink">Learning Paths</div>
          <p className="text-xs text-faint mt-0.5">Canonical, hands-on courses for the platform — authored in the <a href="https://github.com/open-lmx" target="_blank" rel="noreferrer" className="text-accent hover:underline">open-lmx</a> course format.</p>
        </div>
      </div>

      {loading && <div className="text-faint text-sm animate-pulse">Loading paths…</div>}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        {paths.map(p => {
          const done = p.modules.filter(m => m.done).length
          const external = !!p.href
          const started = p.progress > 0
          return (
            <div key={p.id} className="rounded-xl border border-line bg-surface/60 p-5 flex flex-col">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="font-medium text-ink leading-snug">{p.title}</div>
                  <p className="text-xs text-faint mt-1 leading-relaxed">{p.description}</p>
                </div>
                <span className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium ring-1 ${LEVEL_TONE[p.level]}`}>{p.level}</span>
              </div>

              {p.source && (
                <span className="mt-2 inline-flex w-max items-center gap-1 rounded-full bg-raised/70 border border-line px-2 py-0.5 text-[10px] text-faint">
                  Reference · {p.source}
                </span>
              )}

              {!external && (
                <>
                  <div className="mt-4">
                    <div className="flex items-center justify-between text-[11px] text-faint mb-1.5">
                      <span>{done} / {p.modules.length} modules</span>
                      <span className="nums">{Math.round(p.progress * 100)}%</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-line overflow-hidden">
                      <div className="h-full rounded-full bg-gradient-to-r from-accent-strong to-accent" style={{ width: `${Math.round(p.progress * 100)}%` }} />
                    </div>
                  </div>
                  <ul className="mt-3 space-y-1.5">
                    {p.modules.map(m => (
                      <li key={m.title} className="flex items-center gap-2 text-xs">
                        {m.done ? <CheckCircle2 size={14} className="text-ok shrink-0" /> : <Circle size={14} className="text-faint shrink-0" />}
                        <span className={m.done ? 'text-muted line-through' : 'text-ink'}>{m.title}</span>
                      </li>
                    ))}
                  </ul>
                </>
              )}

              <div className="mt-4 pt-3 border-t border-line flex items-center justify-between">
                <div className="flex items-center gap-3 text-[11px] text-faint">
                  <span className="inline-flex items-center gap-1"><Clock size={12} /> {p.duration_min >= 120 ? `${Math.round(p.duration_min / 60)}h` : `${p.duration_min} min`}</span>
                  {p.enrolled > 0 && <span className="inline-flex items-center gap-1"><Users size={12} /> {p.enrolled.toLocaleString()}</span>}
                </div>
                {external ? (
                  <a href={p.href} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 rounded-lg border border-line hover:border-line-strong text-muted hover:text-ink text-xs font-medium px-3.5 py-1.5 transition-colors">
                    View source <ExternalLink size={12} />
                  </a>
                ) : (
                  <button onClick={() => setOpen(p)} className="rounded-lg bg-accent-strong hover:bg-accent text-white text-xs font-medium px-3.5 py-1.5 transition-colors">
                    {started ? 'Continue' : 'Start'}
                  </button>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
