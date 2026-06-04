import { useEffect, useState } from 'react'
import { api, type AgentProfile } from '../api'
import { Badge, statusVariant } from '../components/Badge'
import { Bot, Cpu, ShieldCheck } from 'lucide-react'

export function AgentsView() {
  const [agents, setAgents] = useState<AgentProfile[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.agentRoster().then(setAgents).catch(() => setAgents([])).finally(() => setLoading(false))
  }, [])

  return (
    <div className="space-y-4">
      {loading && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-40 rounded-xl border border-line bg-raised/40 animate-pulse" />)}
        </div>
      )}

      {!loading && agents.length > 0 && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {agents.map(a => (
            <div key={a.id} className="rounded-xl border border-line bg-raised/70 p-4 hover:border-line-strong transition-colors">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-accent/12 text-accent ring-1 ring-accent/25 grid place-items-center">
                  <Bot size={18} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <h3 className="text-sm font-semibold text-ink capitalize truncate">{a.role}</h3>
                    <Badge label={a.status} variant={statusVariant(a.status)} />
                  </div>
                  <p className="text-xs text-faint truncate">{a.space}</p>
                </div>
              </div>

              {a.current_task && (
                <p className="mt-3 text-xs text-muted line-clamp-2 min-h-8">{a.current_task}</p>
              )}

              <div className="mt-3 flex flex-wrap gap-1.5">
                {a.skills.slice(0, 4).map(s => (
                  <span key={s} className="text-[10px] rounded-md bg-surface text-muted ring-1 ring-line px-1.5 py-0.5">{s}</span>
                ))}
              </div>

              <div className="mt-4 pt-3 border-t border-line flex items-center gap-4 text-[11px] text-faint nums">
                <span className="inline-flex items-center gap-1"><Cpu size={12} /> {a.model}</span>
                <span>{a.runs} runs</span>
                <span className="inline-flex items-center gap-1 ml-auto">
                  <ShieldCheck size={12} className={a.trust >= 0.7 ? 'text-ok' : a.trust >= 0.5 ? 'text-warn' : 'text-bad'} />
                  {(a.trust * 100).toFixed(0)}%
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
