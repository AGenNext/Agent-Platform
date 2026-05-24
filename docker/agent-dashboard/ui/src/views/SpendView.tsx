import { useEffect, useState } from 'react'
import { Card, CardHeader } from '../components/Card'
import { Badge } from '../components/Badge'
import { RefreshCw, Search, Zap } from 'lucide-react'

interface ModelRow { model_id: string; provider: string; total_cost: number; calls: number; avg_cost: number }
interface ObjectiveRow { objective_id: string; total_cost: number; total_input: number; total_output: number; calls: number }
interface DiscoveredModel {
  model_id: string; provider: string; display_name: string
  is_local: boolean; is_available: boolean
  cost_per_1k_input: number; cost_per_1k_output: number
  capabilities: Record<string, boolean>
  context_window?: number
}
interface SelectResult {
  model_id: string; provider: string; score: number
  score_breakdown: { speed: number; cost: number; accuracy: number }
  rationale: string; context: Record<string, unknown>
}

const PROVIDERS: Record<string, string> = {
  anthropic: 'bg-purple-900/30 text-purple-300 border-purple-800',
  ollama:    'bg-emerald-900/30 text-emerald-300 border-emerald-800',
  openai:    'bg-teal-900/30 text-teal-300 border-teal-800',
  cohere:    'bg-blue-900/30 text-blue-300 border-blue-800',
}

function ProviderBadge({ provider }: { provider: string }) {
  const cls = PROVIDERS[provider] ?? 'bg-slate-800 text-slate-300 border-slate-700'
  return <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium border ${cls}`}>{provider}</span>
}

function Bar({ value, max, color = 'bg-indigo-500' }: { value: number; max: number; color?: string }) {
  const pct = max > 0 ? Math.min((value / max) * 100, 100) : 0
  return (
    <div className="flex items-center gap-2">
      <div className="flex-1 bg-[#1f2937] rounded-full h-1.5">
        <div className={`h-1.5 rounded-full ${color} transition-all`} style={{ width: `${pct}%` }} />
      </div>
      <span className="text-xs text-slate-400 w-16 text-right">${value.toFixed(4)}</span>
    </div>
  )
}

function ScoreBar({ value, label }: { value: number; label: string }) {
  const color = value >= 0.7 ? 'bg-emerald-500' : value >= 0.4 ? 'bg-amber-500' : 'bg-red-500'
  return (
    <div>
      <div className="text-xs text-slate-500 mb-0.5">{label}</div>
      <div className="flex items-center gap-1.5">
        <div className="flex-1 bg-[#1f2937] rounded-full h-1">
          <div className={`h-1 rounded-full ${color}`} style={{ width: `${value * 100}%` }} />
        </div>
        <span className="text-xs text-slate-400">{(value * 100).toFixed(0)}%</span>
      </div>
    </div>
  )
}

export function SpendView() {
  const [byModel, setByModel] = useState<ModelRow[]>([])
  const [byObjective, setByObjective] = useState<ObjectiveRow[]>([])
  const [models, setModels] = useState<DiscoveredModel[]>([])
  const [loading, setLoading] = useState(true)
  const [discovering, setDiscovering] = useState(false)
  const [selectResult, setSelectResult] = useState<SelectResult | null>(null)
  const [taskType, setTaskType] = useState('generation')

  async function load() {
    setLoading(true)
    try {
      const [m, o, disc] = await Promise.all([
        fetch('/api/model-router/usage/by-model').then(r => r.json()),
        fetch('/api/model-router/usage/by-objective').then(r => r.json()),
        fetch('/api/model-router/models').then(r => r.json()),
      ])
      setByModel(Array.isArray(m) ? m : [])
      setByObjective(Array.isArray(o) ? o : [])
      setModels(Array.isArray(disc) ? disc : [])
    } finally {
      setLoading(false)
    }
  }

  async function discover() {
    setDiscovering(true)
    try {
      await fetch('/api/model-router/discover', { method: 'POST' })
      await load()
    } finally {
      setDiscovering(false)
    }
  }

  async function trySelect() {
    const r = await fetch('/api/model-router/select', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task_type: taskType }),
    })
    setSelectResult(await r.json())
  }

  useEffect(() => { load() }, [])

  const maxModelCost = Math.max(...byModel.map(m => m.total_cost), 0.0001)
  const maxObjCost   = Math.max(...byObjective.map(o => o.total_cost), 0.0001)

  const localModels  = models.filter(m => m.is_local)
  const cloudModels  = models.filter(m => !m.is_local)

  return (
    <div className="space-y-4">
      {/* Router tester */}
      <Card>
        <CardHeader title="Intelligent Router" action={
          <button onClick={load} className="flex items-center gap-1 text-xs px-3 py-1 rounded bg-[#1a2233] text-slate-400 hover:text-slate-200 border border-[#2d3748] transition-colors">
            <RefreshCw size={11} className={loading ? 'animate-spin' : ''} /> Refresh
          </button>
        } />
        <div className="flex gap-2 mb-3">
          <select
            className="bg-[#0d1117] border border-[#1f2937] rounded px-3 py-1.5 text-sm text-slate-200 focus:outline-none focus:border-indigo-500"
            value={taskType}
            onChange={e => setTaskType(e.target.value)}
          >
            {['research', 'generation', 'eval', 'generic'].map(t => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
          <button onClick={trySelect}
            className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-indigo-600 hover:bg-indigo-500 text-white transition-colors">
            <Search size={12} /> Select model
          </button>
          <button onClick={discover} disabled={discovering}
            className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-emerald-900/40 text-emerald-400 hover:bg-emerald-900/60 border border-emerald-800 disabled:opacity-40 transition-colors">
            <Zap size={12} /> {discovering ? 'Discovering...' : 'Re-discover'}
          </button>
        </div>

        {selectResult && (
          <div className="p-3 rounded-lg bg-[#0d1117] border border-indigo-800/50 space-y-2">
            <div className="flex items-center gap-2">
              <span className="text-sm font-semibold text-slate-200">{selectResult.model_id}</span>
              <ProviderBadge provider={selectResult.provider} />
              <span className="text-xs text-slate-500 ml-auto">score {(selectResult.score * 100).toFixed(0)}%</span>
            </div>
            <div className="grid grid-cols-3 gap-2">
              <ScoreBar value={selectResult.score_breakdown.speed}    label="Speed" />
              <ScoreBar value={selectResult.score_breakdown.cost}     label="Cost" />
              <ScoreBar value={selectResult.score_breakdown.accuracy} label="Accuracy" />
            </div>
            <div className="text-xs text-slate-500 italic">{selectResult.rationale}</div>
          </div>
        )}
      </Card>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Spend by model */}
        <Card>
          <CardHeader title="Spend by model" />
          {byModel.length === 0
            ? <div className="text-slate-500 text-sm">No usage recorded yet.</div>
            : byModel.map(row => (
              <div key={`${row.provider}/${row.model_id}`} className="mb-3">
                <div className="flex items-center gap-2 mb-1">
                  <ProviderBadge provider={row.provider} />
                  <span className="text-xs text-slate-300 truncate">{row.model_id}</span>
                  <span className="text-xs text-slate-600 ml-auto">{row.calls} calls</span>
                </div>
                <Bar value={row.total_cost} max={maxModelCost} color="bg-indigo-500" />
              </div>
            ))
          }
        </Card>

        {/* Spend by objective */}
        <Card>
          <CardHeader title="Spend by objective" />
          {byObjective.length === 0
            ? <div className="text-slate-500 text-sm">No usage recorded yet.</div>
            : byObjective.map(row => (
              <div key={row.objective_id} className="mb-3">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs text-slate-300 font-mono truncate max-w-40">{row.objective_id}</span>
                  <span className="text-xs text-slate-600 ml-auto">{row.calls} calls</span>
                </div>
                <Bar value={row.total_cost} max={maxObjCost} color="bg-amber-500" />
              </div>
            ))
          }
        </Card>
      </div>

      {/* Discovered model registry */}
      <Card>
        <CardHeader title={`Model Registry (${models.length} discovered)`} />
        {models.length === 0 && (
          <div className="text-slate-500 text-sm">
            No models discovered yet. Click "Re-discover" to probe providers.
          </div>
        )}
        {[{ label: 'Local (Ollama)', list: localModels }, { label: 'Cloud', list: cloudModels }]
          .filter(g => g.list.length > 0)
          .map(group => (
            <div key={group.label} className="mb-4">
              <div className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">{group.label}</div>
              <div className="space-y-2">
                {group.list.map(m => (
                  <div key={`${m.provider}/${m.model_id}`}
                    className={`flex items-center gap-3 p-2.5 rounded-lg border ${
                      m.is_available ? 'border-[#1f2937] bg-[#0d1117]' : 'border-red-900/40 bg-red-900/5 opacity-50'
                    }`}>
                    <ProviderBadge provider={m.provider} />
                    <div className="flex-1 min-w-0">
                      <div className="text-sm text-slate-200 truncate">{m.display_name}</div>
                      <div className="flex flex-wrap gap-x-2 gap-y-0 mt-0.5">
                        {Object.entries(m.capabilities || {})
                          .filter(([, v]) => v)
                          .map(([k]) => (
                            <span key={k} className="text-xs text-slate-600">{k}</span>
                          ))}
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      {m.is_local
                        ? <Badge label="free" variant="green" />
                        : <span className="text-xs text-slate-400">
                            ${m.cost_per_1k_input}/1k in · ${m.cost_per_1k_output}/1k out
                          </span>
                      }
                      {m.context_window && (
                        <div className="text-xs text-slate-600 mt-0.5">{(m.context_window / 1000).toFixed(0)}k ctx</div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))
        }
      </Card>
    </div>
  )
}
