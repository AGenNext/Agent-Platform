import { useEffect, useMemo, useState } from 'react'
import { api, type Space } from '../api'
import { Badge, statusVariant } from '../components/Badge'
import { Box, GitBranch, Plus, Search, ShieldCheck, Sparkles } from 'lucide-react'

const KIND_HUE: Record<string, string> = {
  research:   'from-sky-500/30 to-indigo-500/10',
  generation: 'from-violet-500/30 to-fuchsia-500/10',
  eval:       'from-emerald-500/30 to-teal-500/10',
  generic:    'from-slate-500/30 to-slate-600/10',
}

const FILTERS = ['All', 'Running', 'Completed', 'Draft'] as const
type Filter = (typeof FILTERS)[number]

export function SpacesView() {
  const [spaces, setSpaces] = useState<Space[]>([])
  const [loading, setLoading] = useState(true)
  const [q, setQ] = useState('')
  const [filter, setFilter] = useState<Filter>('All')

  useEffect(() => {
    api.listSpaces().then(setSpaces).catch(() => setSpaces([])).finally(() => setLoading(false))
  }, [])

  const shown = useMemo(() => spaces.filter(s => {
    const matchesQ = !q || (s.name + s.description + s.owner).toLowerCase().includes(q.toLowerCase())
    const matchesF =
      filter === 'All' ||
      (filter === 'Running' && s.status === 'running') ||
      (filter === 'Completed' && s.status === 'completed') ||
      (filter === 'Draft' && (s.status === 'draft' || s.status === 'pending'))
    return matchesQ && matchesF
  }), [spaces, q, filter])

  return (
    <div className="space-y-6">
      {/* Toolbar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="relative w-full sm:max-w-sm">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-faint" />
          <input
            value={q}
            onChange={e => setQ(e.target.value)}
            placeholder="Search spaces…"
            className="w-full rounded-lg border border-line bg-field/70 pl-9 pr-3 py-2 text-sm text-ink placeholder:text-faint focus:outline-none focus:border-accent transition-colors"
          />
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1 rounded-lg border border-line bg-surface/60 p-1">
            {FILTERS.map(f => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-2.5 py-1 rounded-md text-xs font-medium transition-colors ${
                  filter === f ? 'bg-raised text-ink ring-1 ring-line-strong' : 'text-muted hover:text-ink'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
          <button className="inline-flex items-center gap-1.5 rounded-lg bg-accent-strong hover:bg-accent px-3 py-2 text-sm font-medium text-white transition-colors shadow-lg shadow-accent-strong/20">
            <Plus size={15} /> New Space
          </button>
        </div>
      </div>

      {loading && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="h-44 rounded-xl border border-line bg-raised/40 animate-pulse" />
          ))}
        </div>
      )}

      {!loading && shown.length === 0 && (
        <div className="rounded-xl border border-dashed border-line-strong bg-surface/40 py-16 text-center">
          <Sparkles size={22} className="mx-auto text-faint" />
          <p className="mt-3 text-sm text-muted">No spaces match.</p>
          <p className="text-xs text-faint">Create a space to start an agent workspace.</p>
        </div>
      )}

      {!loading && shown.length > 0 && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {shown.map(s => (
            <button
              key={s.id}
              className="group text-left rounded-xl border border-line bg-raised/70 overflow-hidden transition-all hover:border-line-strong hover:-translate-y-0.5 hover:shadow-[0_16px_40px_-20px_rgba(0,0,0,0.8)]"
            >
              {/* Banner */}
              <div className={`relative h-20 bg-gradient-to-br ${KIND_HUE[s.kind] ?? KIND_HUE.generic}`}>
                <div className="absolute inset-0 opacity-40 [background-image:radial-gradient(circle_at_1px_1px,rgba(255,255,255,0.18)_1px,transparent_0)] [background-size:12px_12px]" />
                <div className="absolute top-3 right-3">
                  <Badge label={s.status} variant={statusVariant(s.status)} />
                </div>
                <div className="absolute -bottom-4 left-4 w-9 h-9 rounded-lg bg-surface ring-1 ring-line-strong flex items-center justify-center text-accent">
                  <Box size={16} />
                </div>
              </div>

              {/* Body */}
              <div className="px-4 pt-6 pb-4">
                <div className="flex items-center gap-2">
                  <h3 className="text-sm font-semibold text-ink truncate group-hover:text-accent transition-colors">{s.name}</h3>
                  <span className="text-[11px] text-faint shrink-0">{s.kind}</span>
                </div>
                <p className="mt-1 text-xs text-faint">by {s.owner}</p>
                <p className="mt-2 text-xs text-muted line-clamp-2 min-h-8">{s.description}</p>

                <div className="mt-3 flex items-center gap-4 text-[11px] text-faint nums">
                  <span className="inline-flex items-center gap-1"><GitBranch size={12} /> {s.runs} runs</span>
                  <span className="inline-flex items-center gap-1"><Box size={12} /> {s.artifacts}</span>
                  <span className="inline-flex items-center gap-1"><ShieldCheck size={12} className={s.trust >= 0.7 ? 'text-ok' : s.trust >= 0.5 ? 'text-warn' : 'text-bad'} /> {(s.trust * 100).toFixed(0)}%</span>
                  <span className="ml-auto">{new Date(s.updated_at).toLocaleDateString()}</span>
                </div>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
