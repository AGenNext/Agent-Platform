import { useEffect, useState } from 'react'
import { api, type LearningPath } from '../api'
import { CheckCircle2, Circle, Clock, GraduationCap, Users } from 'lucide-react'

const LEVEL_TONE: Record<LearningPath['level'], string> = {
  Beginner: 'text-ok bg-ok/10 ring-ok/20',
  Intermediate: 'text-info bg-info/10 ring-info/20',
  Advanced: 'text-accent bg-accent/10 ring-accent/20',
}

export function LearningPathsView() {
  const [paths, setPaths] = useState<LearningPath[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.learningPaths().then(setPaths).catch(() => setPaths([])).finally(() => setLoading(false))
  }, [])

  return (
    <div className="space-y-4">
      <div className="rounded-xl border border-line bg-gradient-to-br from-accent/10 via-surface/40 to-surface/40 p-5 flex items-center gap-4">
        <div className="w-11 h-11 rounded-xl bg-accent/15 text-accent ring-1 ring-accent/25 grid place-items-center shrink-0">
          <GraduationCap size={22} />
        </div>
        <div>
          <div className="text-sm font-semibold text-ink">Learning Paths</div>
          <p className="text-xs text-faint mt-0.5">Guided tracks for building, governing, and evaluating agents on the platform.</p>
        </div>
      </div>

      {loading && <div className="text-faint text-sm animate-pulse">Loading paths…</div>}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        {paths.map(p => {
          const done = p.modules.filter(m => m.done).length
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
                    {m.done
                      ? <CheckCircle2 size={14} className="text-ok shrink-0" />
                      : <Circle size={14} className="text-faint shrink-0" />}
                    <span className={m.done ? 'text-muted line-through' : 'text-ink'}>{m.title}</span>
                  </li>
                ))}
              </ul>

              <div className="mt-4 pt-3 border-t border-line flex items-center justify-between">
                <div className="flex items-center gap-3 text-[11px] text-faint">
                  <span className="inline-flex items-center gap-1"><Clock size={12} /> {p.duration_min} min</span>
                  <span className="inline-flex items-center gap-1"><Users size={12} /> {p.enrolled.toLocaleString()}</span>
                </div>
                <button className="rounded-lg bg-accent-strong hover:bg-accent text-white text-xs font-medium px-3.5 py-1.5 transition-colors">
                  {started ? 'Continue' : 'Start'}
                </button>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
