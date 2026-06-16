import { useEffect, useState } from 'react'
import { providers } from '../connectors/registry'
import type { ProviderStatus, SocialComment, SocialProvider } from '../connectors/types'
import { Badge } from '../components/Badge'
import { Plug, RefreshCw } from 'lucide-react'

const STATUS_BADGE: Record<ProviderStatus, { label: string; variant: 'green' | 'yellow' | 'gray' }> = {
  connected: { label: 'connected', variant: 'green' },
  mock: { label: 'mock data', variant: 'yellow' },
  coming_soon: { label: 'coming soon', variant: 'gray' },
}

export function ConnectorsView() {
  const [selected, setSelected] = useState<SocialProvider>(providers[0])
  const [comments, setComments] = useState<SocialComment[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function load(p: SocialProvider) {
    setSelected(p); setError(null)
    if (p.status === 'coming_soon') { setComments([]); return }
    setLoading(true)
    try {
      setComments(await p.listComments())
    } catch (e) {
      setError(String(e)); setComments([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load(providers[0]) }, [])

  return (
    <div className="space-y-4">
      <div className="rounded-xl border border-line bg-gradient-to-br from-accent/10 via-surface/40 to-surface/40 p-5 flex items-center gap-4">
        <div className="w-11 h-11 rounded-xl bg-accent/15 text-accent ring-1 ring-accent/25 grid place-items-center shrink-0">
          <Plug size={22} />
        </div>
        <div>
          <div className="text-sm font-semibold text-ink">Connectors</div>
          <p className="text-xs text-faint mt-0.5">Provider-agnostic social inbox. Facebook is live-ready — it flips from mock to real Graph data once an access token is supplied. Only consented data the token is authorized on is ever read.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[280px_1fr] gap-4">
        {/* Providers */}
        <aside className="space-y-2">
          {providers.map(p => {
            const b = STATUS_BADGE[p.status]
            const on = selected.id === p.id
            return (
              <button
                key={p.id}
                onClick={() => load(p)}
                disabled={p.status === 'coming_soon'}
                className={`w-full text-left rounded-xl border p-3.5 transition-all disabled:opacity-55 disabled:cursor-not-allowed ${
                  on ? 'border-accent/50 bg-accent/10 ring-1 ring-accent/20' : 'border-line bg-surface/60 hover:border-line-strong hover:bg-raised/40'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <span className={`w-7 h-7 rounded-lg grid place-items-center text-xs font-bold shrink-0 ${on ? 'bg-accent/15 text-accent ring-1 ring-accent/25' : 'bg-field/60 text-muted ring-1 ring-line'}`}>{p.name.charAt(0)}</span>
                  <span className="text-sm font-medium text-ink flex-1">{p.name}</span>
                  <Badge label={b.label} variant={b.variant} />
                </div>
                <p className="text-[11px] text-faint mt-1.5 leading-snug">{p.description}</p>
              </button>
            )
          })}
        </aside>

        {/* Comments inbox */}
        <div className="rounded-xl border border-line bg-surface/60 overflow-hidden">
          <div className="px-5 py-3 border-b border-line flex items-center justify-between">
            <div className="text-[11px] font-semibold uppercase tracking-[0.13em] text-muted">{selected.name} · Comments</div>
            <button onClick={() => load(selected)} disabled={selected.status === 'coming_soon'} className="inline-flex items-center gap-1.5 text-[11px] text-muted hover:text-ink disabled:opacity-40 rounded-md px-2 py-1 hover:bg-raised transition-colors">
              <RefreshCw size={12} /> Refresh
            </button>
          </div>

          {selected.status === 'mock' && (
            <div className="px-5 pt-3 text-[11px] text-warn">Showing sample data — set <span className="font-mono">VITE_FB_TOKEN</span> and <span className="font-mono">VITE_FB_PAGE_ID</span> to read live comments.</div>
          )}
          {error && <div className="px-5 pt-3 text-[11px] text-bad font-mono">{error}</div>}

          <div className="p-4 space-y-2">
            {loading && <div className="text-faint text-sm animate-pulse">Loading…</div>}
            {!loading && selected.status === 'coming_soon' && (
              <div className="text-center py-10 text-faint text-sm">{selected.name} connector is coming soon.</div>
            )}
            {!loading && selected.status !== 'coming_soon' && comments.length === 0 && (
              <div className="text-center py-10 text-faint text-sm">No comments.</div>
            )}
            {comments.map(c => (
              <div key={c.id} className="rounded-lg border border-line bg-field/40 p-3.5">
                <div className="flex items-center gap-2.5 mb-1">
                  <div className="w-7 h-7 rounded-full bg-accent/15 text-accent ring-1 ring-accent/25 grid place-items-center text-xs font-semibold">
                    {c.author.charAt(0)}
                  </div>
                  <span className="text-sm font-medium text-ink">{c.author}</span>
                  <span className="text-[11px] text-faint">· {new Date(c.createdAt).toLocaleDateString()}</span>
                  {typeof c.likes === 'number' && <span className="ml-auto text-[11px] text-faint nums">♥ {c.likes}</span>}
                </div>
                <p className="text-sm text-muted leading-relaxed">{c.text}</p>
                <div className="mt-1.5 text-[11px] text-faint truncate">on {c.target}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
