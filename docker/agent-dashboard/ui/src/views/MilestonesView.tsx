import { useEffect, useState } from 'react'
import { api, type Milestone } from '../api'
import { Badge, statusVariant } from '../components/Badge'
import { CalendarClock, Layers } from 'lucide-react'

function daysUntil(iso: string): string {
  const d = Math.ceil((new Date(iso).getTime() - Date.now()) / 86_400_000)
  if (d < 0) return `${Math.abs(d)}d overdue`
  if (d === 0) return 'due today'
  return `in ${d}d`
}

function Ring({ value }: { value: number }) {
  const pct = Math.round(value * 100)
  const tone = value >= 0.8 ? 'text-ok' : value >= 0.4 ? 'text-accent' : 'text-warn'
  return (
    <div className="relative w-11 h-11 shrink-0">
      <svg viewBox="0 0 36 36" className="w-11 h-11 -rotate-90">
        <circle cx="18" cy="18" r="15.5" fill="none" stroke="currentColor" strokeWidth="3" className="text-line" />
        <circle
          cx="18" cy="18" r="15.5" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round"
          className={tone}
          strokeDasharray={`${2 * Math.PI * 15.5}`}
          strokeDashoffset={`${2 * Math.PI * 15.5 * (1 - value)}`}
        />
      </svg>
      <span className={`absolute inset-0 grid place-items-center text-[11px] font-semibold nums ${tone}`}>{pct}</span>
    </div>
  )
}

export function MilestonesView() {
  const [items, setItems] = useState<Milestone[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.listMilestones().then(setItems).catch(() => setItems([])).finally(() => setLoading(false))
  }, [])

  return (
    <div className="space-y-4">
      {loading && Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="h-20 rounded-xl border border-line bg-raised/40 animate-pulse" />
      ))}

      {!loading && items.length === 0 && (
        <div className="rounded-xl border border-dashed border-line-strong bg-surface/40 py-16 text-center">
          <Layers size={22} className="mx-auto text-faint" />
          <p className="mt-3 text-sm text-muted">No milestones yet.</p>
        </div>
      )}

      {!loading && items.map(m => {
        const overdue = new Date(m.due_at).getTime() < Date.now() && m.status !== 'completed'
        return (
          <div key={m.id} className="rounded-xl border border-line bg-raised/70 p-5 flex items-center gap-5 hover:border-line-strong transition-colors">
            <Ring value={m.progress} />
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <h3 className="text-sm font-semibold text-ink truncate">{m.name}</h3>
                <Badge label={m.status} variant={statusVariant(m.status)} />
              </div>
              <div className="mt-1 flex items-center gap-3 text-xs text-faint">
                <span className="inline-flex items-center gap-1"><Layers size={12} /> {m.space}</span>
                <span className="nums">{m.tasks_done}/{m.tasks_total} tasks</span>
                <span>· {m.owner}</span>
              </div>
              <div className="mt-3 h-1.5 rounded-full bg-line overflow-hidden">
                <div
                  className={`h-full rounded-full ${m.progress >= 0.8 ? 'bg-ok' : m.progress >= 0.4 ? 'bg-accent' : 'bg-warn'}`}
                  style={{ width: `${Math.round(m.progress * 100)}%` }}
                />
              </div>
            </div>
            <div className={`shrink-0 inline-flex items-center gap-1.5 text-xs ${overdue ? 'text-bad' : 'text-muted'}`}>
              <CalendarClock size={13} />
              <span className="nums">{daysUntil(m.due_at)}</span>
            </div>
          </div>
        )
      })}
    </div>
  )
}
