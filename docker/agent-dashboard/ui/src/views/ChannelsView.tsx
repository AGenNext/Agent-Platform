import { useEffect, useState } from 'react'
import { api, type Channel } from '../api'
import { Bot, Hash, Send, Server, User } from 'lucide-react'

type Msg = { author: string; role: 'agent' | 'system' | 'human'; text: string; at: string }

// Presentational sample thread per channel kind (UI-only, no runtime logic).
const THREADS: Record<string, Msg[]> = {
  agent: [
    { author: 'planner', role: 'agent', text: 'Decomposed objective into 3 tasks: research, draft, review.', at: '09:00' },
    { author: 'researcher', role: 'agent', text: 'Pulled 12 sources on the 3 shortlisted vendors. Confidence high on pricing, low on SLAs.', at: '09:02' },
    { author: 'system', role: 'system', text: 'Handoff researcher → writer accepted.', at: '09:03' },
    { author: 'writer', role: 'agent', text: 'Drafting comparison deck v2. Flagging 2 claims for human review.', at: '09:05' },
  ],
  system: [
    { author: 'governance', role: 'system', text: 'Policy AGX-RUNTIME-DEFAULT evaluated: allow.', at: '08:58' },
    { author: 'trust', role: 'system', text: 'Artifact aa11 trust score updated → 82% (7 evidence links).', at: '09:06' },
  ],
  human: [
    { author: 'you', role: 'human', text: 'Prioritize the vendor with the best SLA terms.', at: '09:07' },
    { author: 'planner', role: 'agent', text: 'Acknowledged — re-ranking on SLA weight.', at: '09:07' },
  ],
}

const roleIcon = (r: Msg['role']) =>
  r === 'agent' ? <Bot size={13} /> : r === 'system' ? <Server size={13} /> : <User size={13} />

export function ChannelsView() {
  const [channels, setChannels] = useState<Channel[]>([])
  const [active, setActive] = useState<Channel | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.listChannels()
      .then(cs => { setChannels(cs); setActive(cs[0] ?? null) })
      .catch(() => setChannels([]))
      .finally(() => setLoading(false))
  }, [])

  const thread = active ? (THREADS[active.kind] ?? []) : []

  return (
    <div className="grid grid-cols-1 md:grid-cols-[260px_1fr] gap-4 h-[calc(100vh-9.5rem)]">
      {/* Channel list */}
      <div className="rounded-xl border border-line bg-surface/60 overflow-hidden flex flex-col">
        <div className="px-4 py-3 border-b border-line text-[11px] font-semibold uppercase tracking-[0.13em] text-muted">Channels</div>
        <div className="flex-1 overflow-auto p-2 space-y-0.5">
          {loading && Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-9 rounded-lg bg-raised/40 animate-pulse" />)}
          {!loading && channels.map(c => {
            const on = active?.id === c.id
            return (
              <button
                key={c.id}
                onClick={() => setActive(c)}
                className={`w-full flex items-center gap-2 px-2.5 py-2 rounded-lg text-sm transition-colors ${
                  on ? 'bg-raised text-ink ring-1 ring-line-strong' : 'text-muted hover:text-ink hover:bg-raised/50'
                }`}
              >
                <Hash size={14} className={on ? 'text-accent' : 'text-faint'} />
                <span className="truncate flex-1 text-left">{c.name}</span>
                {c.unread > 0 && (
                  <span className="text-[10px] font-semibold rounded-full bg-accent/15 text-accent px-1.5 py-0.5 nums">{c.unread}</span>
                )}
              </button>
            )
          })}
        </div>
      </div>

      {/* Thread */}
      <div className="rounded-xl border border-line bg-raised/60 overflow-hidden flex flex-col">
        <div className="px-5 py-3 border-b border-line flex items-center gap-2">
          <Hash size={15} className="text-accent" />
          <span className="text-sm font-semibold text-ink">{active?.name ?? '—'}</span>
          {active && <span className="text-xs text-faint">· {active.kind} channel</span>}
        </div>

        <div className="flex-1 overflow-auto px-5 py-4 space-y-4">
          {thread.map((m, i) => (
            <div key={i} className="flex gap-3">
              <div className={`mt-0.5 w-7 h-7 shrink-0 rounded-lg flex items-center justify-center ring-1 ${
                m.role === 'agent' ? 'bg-accent/12 text-accent ring-accent/25'
                : m.role === 'system' ? 'bg-info/12 text-info ring-info/25'
                : 'bg-ok/12 text-ok ring-ok/25'
              }`}>
                {roleIcon(m.role)}
              </div>
              <div className="min-w-0">
                <div className="flex items-baseline gap-2">
                  <span className="text-sm font-medium text-ink">{m.author}</span>
                  <span className="text-[11px] text-faint nums">{m.at}</span>
                </div>
                <p className="text-sm text-muted mt-0.5">{m.text}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="px-4 py-3 border-t border-line">
          <div className="flex items-center gap-2 rounded-lg border border-line bg-field/70 px-3 py-2">
            <input
              disabled
              placeholder={`Message #${active?.name ?? ''}`}
              className="flex-1 bg-transparent text-sm text-ink placeholder:text-faint focus:outline-none"
            />
            <Send size={15} className="text-faint" />
          </div>
        </div>
      </div>
    </div>
  )
}
