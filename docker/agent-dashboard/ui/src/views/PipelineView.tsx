import { useEffect, useState } from 'react'
import { api } from '../api'
import { ArrowRight, CheckCircle2, GitBranch, Wand2, Play, ShieldCheck, Boxes, Radio } from 'lucide-react'

type Stage = {
  id: string
  label: string
  sub: string
  icon: React.ReactNode
  target: string
  metric: string
  status: 'ok' | 'running' | 'pending'
}

const STATUS_DOT: Record<Stage['status'], string> = {
  ok: 'bg-ok shadow-[0_0_8px] shadow-ok/50',
  running: 'bg-accent shadow-[0_0_8px] shadow-accent/50 animate-pulse',
  pending: 'bg-faint',
}

export function PipelineView({ onNavigate }: { onNavigate: (v: string) => void }) {
  const [stages, setStages] = useState<Stage[]>(seed())

  useEffect(() => {
    Promise.allSettled([api.listObjectives(), api.hubArtifacts(), api.gatewayRoutes()])
      .then(([objs, hub, routes]) => {
        const objectives = objs.status === 'fulfilled' ? objs.value : []
        const artifacts = hub.status === 'fulfilled' ? hub.value : []
        const gw = routes.status === 'fulfilled' ? routes.value : []
        const running = objectives.filter(o => o.status === 'running').length
        const requests = gw.reduce((a, r) => a + r.requests, 0)
        setStages(prev => prev.map(s => {
          if (s.id === 'run') return { ...s, metric: `${running || objectives.length} active`, status: running ? 'running' : s.status }
          if (s.id === 'publish') return { ...s, metric: `${artifacts.length} artifacts` }
          if (s.id === 'operate') return { ...s, metric: requests ? `${requests.toLocaleString()} reqs` : s.metric }
          return s
        }))
      })
  }, [])

  return (
    <div className="space-y-6">
      <div className="rounded-xl border border-line bg-gradient-to-br from-accent/10 via-surface/40 to-surface/40 p-5">
        <div className="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.14em] text-faint mb-1">
          <GitBranch size={13} className="text-accent" /> End-to-end delivery
        </div>
        <div className="text-sm font-semibold text-ink">From a plain-language objective to a governed, deployed agent</div>
        <p className="text-xs text-faint mt-1 leading-relaxed">
          One pipeline across the platform — author, run, evaluate, publish, operate — the agent-delivery analogue of code → build → package → deploy.
        </p>
      </div>

      {/* Pipeline flow */}
      <div className="flex flex-col lg:flex-row lg:items-stretch gap-3 lg:gap-0">
        {stages.map((s, i) => (
          <div key={s.id} className="flex items-center lg:flex-1 lg:flex-col">
            <button
              onClick={() => onNavigate(s.target)}
              className="group relative w-full text-left rounded-xl border border-line bg-surface/60 hover:border-accent/40 hover:bg-raised/50 transition-all p-4 flex-1"
            >
              <span className={`absolute top-4 right-4 w-2 h-2 rounded-full ${STATUS_DOT[s.status]}`} />
              <div className="w-9 h-9 rounded-lg bg-accent/12 text-accent ring-1 ring-accent/25 grid place-items-center mb-3">
                {s.icon}
              </div>
              <div className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wider text-faint mb-0.5">
                Stage {i + 1}
              </div>
              <div className="text-sm font-semibold text-ink">{s.label}</div>
              <p className="text-xs text-faint mt-0.5 leading-snug">{s.sub}</p>
              <div className="mt-3 text-[11px] text-muted nums">{s.metric}</div>
              <span className="mt-2 inline-flex items-center gap-1 text-[11px] text-accent opacity-0 group-hover:opacity-100 transition-opacity">
                Open <ArrowRight size={11} />
              </span>
            </button>
            {i < stages.length - 1 && (
              <div className="shrink-0 grid place-items-center text-faint px-1 lg:px-2 lg:py-3 rotate-90 lg:rotate-0">
                <ArrowRight size={16} />
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Gate summary */}
      <div className="rounded-xl border border-line bg-surface/60 p-5">
        <div className="text-[11px] font-semibold uppercase tracking-[0.13em] text-muted mb-3">Delivery gates</div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {[
            { label: 'Policy gate', detail: 'Runtime policy passes before agents act', icon: <ShieldCheck size={15} /> },
            { label: 'CLEAR eval', detail: 'Composite score ≥ 0.70 to publish', icon: <CheckCircle2 size={15} /> },
            { label: 'Trust gate', detail: 'Evidence-weighted trust threshold', icon: <ShieldCheck size={15} /> },
          ].map(g => (
            <div key={g.label} className="rounded-lg border border-line bg-field/40 p-3.5">
              <div className="flex items-center gap-2 text-ink text-sm font-medium"><span className="text-ok">{g.icon}</span>{g.label}</div>
              <p className="text-xs text-faint mt-1 leading-snug">{g.detail}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function seed(): Stage[] {
  return [
    { id: 'compose', label: 'Compose', sub: 'Author the agent pipeline', icon: <Wand2 size={17} />, target: 'composer', metric: 'Composer', status: 'ok' },
    { id: 'run', label: 'Run', sub: 'Agents propose, the DB records', icon: <Play size={17} />, target: 'objectives', metric: '— active', status: 'pending' },
    { id: 'evaluate', label: 'Evaluate', sub: 'CLEAR scoring + trust', icon: <CheckCircle2 size={17} />, target: 'artifacts', metric: 'Eval & trust', status: 'ok' },
    { id: 'publish', label: 'Publish', sub: 'Artifact registry', icon: <Boxes size={17} />, target: 'hub', metric: '— artifacts', status: 'ok' },
    { id: 'operate', label: 'Operate', sub: 'AI Gateway routing & cost', icon: <Radio size={17} />, target: 'gateway', metric: 'Gateway', status: 'ok' },
  ]
}
