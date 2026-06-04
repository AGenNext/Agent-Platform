import { useEffect, useMemo, useState } from 'react'
import { api, type HubArtifact } from '../api'
import { Badge, statusVariant } from '../components/Badge'
import { Code2, Database, Download, FileText, Presentation, ScrollText, Search } from 'lucide-react'

const TYPE_META: Record<HubArtifact['artifact_type'], { icon: React.ReactNode; label: string }> = {
  deck:    { icon: <Presentation size={15} />, label: 'Deck' },
  doc:     { icon: <FileText size={15} />,     label: 'Doc' },
  dataset: { icon: <Database size={15} />,     label: 'Dataset' },
  code:    { icon: <Code2 size={15} />,        label: 'Code' },
  report:  { icon: <ScrollText size={15} />,   label: 'Report' },
}

const FILTERS = ['all', 'deck', 'doc', 'dataset', 'code', 'report'] as const

export function ArtifactHubView() {
  const [items, setItems] = useState<HubArtifact[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>('all')
  const [q, setQ] = useState('')

  useEffect(() => {
    api.hubArtifacts().then(setItems).catch(() => setItems([])).finally(() => setLoading(false))
  }, [])

  const shown = useMemo(() => items.filter(a =>
    (filter === 'all' || a.artifact_type === filter) &&
    (q === '' || a.title.toLowerCase().includes(q.toLowerCase()) || a.space.toLowerCase().includes(q.toLowerCase()))
  ), [items, filter, q])

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="inline-flex items-center gap-1 rounded-lg border border-line bg-surface/60 p-1">
          {FILTERS.map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-md text-xs font-medium capitalize transition-all ${
                filter === f ? 'bg-raised text-ink shadow-sm ring-1 ring-line-strong' : 'text-muted hover:text-ink'
              }`}
            >
              {f}
            </button>
          ))}
        </div>
        <label className="flex items-center gap-2 rounded-lg border border-line bg-field/60 px-3 py-1.5 w-60 focus-within:border-accent transition-colors">
          <Search size={14} className="text-faint" />
          <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search artifacts…" className="bg-transparent text-sm text-ink placeholder:text-faint focus:outline-none w-full" />
        </label>
      </div>

      {loading && <div className="text-faint text-sm animate-pulse">Loading hub…</div>}
      {!loading && shown.length === 0 && <div className="text-faint text-sm rounded-xl border border-line bg-surface/40 px-5 py-8 text-center">No artifacts match.</div>}

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3">
        {shown.map(a => {
          const meta = TYPE_META[a.artifact_type]
          return (
            <div key={a.id} className="group rounded-xl border border-line bg-surface/60 p-4 hover:border-line-strong hover:bg-raised/50 transition-all">
              <div className="flex items-start justify-between gap-2 mb-3">
                <span className="inline-flex items-center gap-1.5 rounded-lg bg-accent/10 text-accent ring-1 ring-accent/20 px-2 py-1 text-[11px] font-medium">
                  {meta.icon} {meta.label}
                </span>
                <Badge label={a.status} variant={statusVariant(a.status)} />
              </div>
              <div className="font-medium text-ink leading-snug">{a.title}</div>
              <div className="text-xs text-faint mt-0.5">{a.space} · <span className="font-mono">{a.version}</span></div>

              <div className="mt-3 grid grid-cols-2 gap-2 text-[11px]">
                <div className="rounded-lg bg-field/50 px-2.5 py-1.5">
                  <div className="text-faint">Eval</div>
                  <div className={`font-semibold nums ${a.eval_score >= 0.7 ? 'text-ok' : 'text-warn'}`}>{(a.eval_score * 100).toFixed(0)}%</div>
                </div>
                <div className="rounded-lg bg-field/50 px-2.5 py-1.5">
                  <div className="text-faint">Trust</div>
                  <div className="font-semibold nums text-ink">{(a.trust * 100).toFixed(0)}%</div>
                </div>
              </div>

              <div className="mt-3 flex items-center justify-between text-xs text-faint">
                <span className="inline-flex items-center gap-1"><Download size={12} /> {a.downloads.toLocaleString()}</span>
                <button className="text-accent opacity-0 group-hover:opacity-100 transition-opacity hover:text-ink">Open →</button>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
