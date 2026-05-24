import { useEffect, useState } from 'react'
import { api, type EvalTrend, type RoutingSuggestion, type BenchmarkDef, type BenchmarkRun } from '../api'
import Card from '../components/Card'

type Tab = 'trends' | 'suggestions' | 'benchmarks'

const STATUS_COLORS: Record<string, string> = {
  passed:     'text-emerald-400',
  regressed:  'text-red-400',
  failed:     'text-amber-400',
  running:    'text-indigo-400',
  pending:    'text-slate-400',
  applied:    'text-emerald-400',
  dismissed:  'text-slate-500',
}

export function AnalyticsView() {
  const [tab, setTab] = useState<Tab>('trends')

  return (
    <div className="space-y-4">
      <div className="flex gap-1">
        {(['trends', 'suggestions', 'benchmarks'] as Tab[]).map(t => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-3 py-1.5 text-xs rounded transition-colors ${
              tab === t ? 'bg-indigo-800 text-indigo-200' : 'text-slate-500 hover:text-slate-300'
            }`}
          >
            {t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>
      {tab === 'trends'      && <TrendsTab />}
      {tab === 'suggestions' && <SuggestionsTab />}
      {tab === 'benchmarks'  && <BenchmarksTab />}
    </div>
  )
}

// ── Eval Trends ───────────────────────────────────────────────────────────────

function TrendsTab() {
  const [trends, setTrends] = useState<EvalTrend[]>([])
  const [computing, setComputing] = useState(false)

  useEffect(() => { api.listTrends().then(setTrends).catch(() => {}) }, [])

  async function handleCompute() {
    setComputing(true)
    try {
      const computed = await api.computeTrends(7)
      setTrends(computed)
    } catch {}
    setComputing(false)
  }

  // Group by artifact_type
  const byType: Record<string, EvalTrend[]> = {}
  for (const t of trends) {
    const k = t.artifact_type ?? 'unknown'
    if (!byType[k]) byType[k] = []
    byType[k].push(t)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <button
          onClick={handleCompute}
          disabled={computing}
          className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
        >
          {computing ? 'Computing…' : 'Recompute (7 days)'}
        </button>
        <span className="text-xs text-slate-500">{trends.length} data points</span>
      </div>

      {Object.keys(byType).length === 0
        ? <p className="text-xs text-slate-500">No trend data yet. Run some artifact generation then recompute.</p>
        : Object.entries(byType).map(([type, rows]) => (
          <Card key={type} title={type}>
            <table className="w-full text-xs">
              <thead>
                <tr className="text-slate-500 border-b border-[#1f2937]">
                  <th className="text-left py-1.5 font-normal">Date</th>
                  <th className="text-left py-1.5 font-normal">Model</th>
                  <th className="text-left py-1.5 font-normal">Avg</th>
                  <th className="text-left py-1.5 font-normal">Min</th>
                  <th className="text-left py-1.5 font-normal">Max</th>
                  <th className="text-left py-1.5 font-normal">N</th>
                </tr>
              </thead>
              <tbody>
                {rows.map(r => (
                  <tr key={r.id} className="border-b border-[#1f2937]/40">
                    <td className="py-1.5 text-slate-400">{r.period_date}</td>
                    <td className="py-1.5 text-slate-300 font-mono text-[10px]">{r.model_id ?? '—'}</td>
                    <td className="py-1.5">
                      <ScorePill score={r.avg_score} />
                    </td>
                    <td className="py-1.5 text-slate-500">{r.min_score.toFixed(2)}</td>
                    <td className="py-1.5 text-slate-500">{r.max_score.toFixed(2)}</td>
                    <td className="py-1.5 text-slate-600">{r.sample_count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
        ))
      }
    </div>
  )
}

// ── Routing Suggestions ───────────────────────────────────────────────────────

function SuggestionsTab() {
  const [suggestions, setSuggestions] = useState<RoutingSuggestion[]>([])
  const [analysing, setAnalysing] = useState(false)

  useEffect(() => { api.listSuggestions().then(setSuggestions).catch(() => {}) }, [])

  async function handleAnalyse() {
    setAnalysing(true)
    try {
      await api.analyseSuggestions()
      const updated = await api.listSuggestions()
      setSuggestions(updated)
    } catch {}
    setAnalysing(false)
  }

  async function handleResolve(id: string, action: 'applied' | 'dismissed') {
    await api.resolveSuggestion(id, action)
    const updated = await api.listSuggestions()
    setSuggestions(updated)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <button
          onClick={handleAnalyse}
          disabled={analysing}
          className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
        >
          {analysing ? 'Analysing…' : 'Run Analysis'}
        </button>
        <span className="text-xs text-slate-500">{suggestions.filter(s => s.status === 'pending').length} pending</span>
      </div>

      {suggestions.length === 0
        ? <p className="text-xs text-slate-500">No suggestions yet. Run Analysis after accumulating model performance data.</p>
        : suggestions.map(s => (
          <Card key={s.id} title={`${s.task_type ?? 'all tasks'} — ${s.status}`}>
            <div className="space-y-3">
              <p className="text-xs text-slate-300">{s.rationale}</p>

              <div className="grid grid-cols-2 gap-3 text-xs">
                <div>
                  <p className="text-slate-500 mb-1">Current weights</p>
                  <WeightBars weights={s.current_weights} />
                </div>
                <div>
                  <p className="text-slate-500 mb-1">Suggested weights</p>
                  <WeightBars weights={s.suggested_weights} highlight />
                </div>
              </div>

              {s.evidence && (
                <div className="flex gap-4 text-[10px] text-slate-500">
                  <span>Eval: <span className="text-slate-300">{s.evidence.avg_eval_score?.toFixed(3)}</span></span>
                  <span>Latency: <span className="text-slate-300">{s.evidence.avg_latency_ms}ms</span></span>
                  <span>Cost: <span className="text-slate-300">${s.evidence.avg_cost_usd?.toFixed(5)}</span></span>
                  <span>N: <span className="text-slate-300">{s.evidence.sample_count}</span></span>
                </div>
              )}

              {s.status === 'pending' && (
                <div className="flex gap-2">
                  <button onClick={() => handleResolve(s.id, 'applied')} className="px-3 py-1 bg-emerald-800 hover:bg-emerald-700 text-emerald-200 text-xs rounded">Apply</button>
                  <button onClick={() => handleResolve(s.id, 'dismissed')} className="px-3 py-1 bg-slate-700 hover:bg-slate-600 text-slate-300 text-xs rounded">Dismiss</button>
                </div>
              )}
            </div>
          </Card>
        ))
      }
    </div>
  )
}

// ── Benchmarks ────────────────────────────────────────────────────────────────

function BenchmarksTab() {
  const [benchmarks, setBenchmarks] = useState<BenchmarkDef[]>([])
  const [runs, setRuns] = useState<BenchmarkRun[]>([])
  const [selected, setSelected] = useState<string | null>(null)
  const [running, setRunning] = useState<string | null>(null)

  // Create form
  const [name, setName] = useState('')
  const [artType, setArtType] = useState('blog_post')
  const [caseTopic, setCaseTopic] = useState('')
  const [creating, setCreating] = useState(false)

  useEffect(() => {
    api.listBenchmarks().then(setBenchmarks).catch(() => {})
    api.listBenchmarkRuns().then(setRuns).catch(() => {})
  }, [])

  async function handleCreate() {
    if (!name.trim() || !caseTopic.trim()) return
    setCreating(true)
    try {
      await api.createBenchmark({
        name,
        artifact_type: artType,
        test_cases: [{ topic: caseTopic, kb_ids: [], min_eval_score: 0.70 }],
      })
      const updated = await api.listBenchmarks()
      setBenchmarks(updated)
      setName(''); setCaseTopic('')
    } catch {}
    setCreating(false)
  }

  async function handleRun(bmId: string) {
    setRunning(bmId)
    try {
      await api.runBenchmark(bmId)
      const updatedRuns = await api.listBenchmarkRuns()
      setRuns(updatedRuns)
    } catch {}
    setRunning(null)
  }

  return (
    <div className="grid grid-cols-[260px_1fr] gap-6">
      <div className="space-y-4">
        <Card title="Benchmarks">
          {benchmarks.length === 0
            ? <p className="text-xs text-slate-500">No benchmarks yet.</p>
            : benchmarks.map(bm => (
              <button
                key={bm.id}
                onClick={() => setSelected(bm.id)}
                className={`w-full text-left px-3 py-2 rounded border text-xs mb-1 transition-colors ${
                  selected === bm.id ? 'border-indigo-600 bg-indigo-900/30 text-white' : 'border-[#1f2937] text-slate-400 hover:border-slate-600'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="font-medium">{bm.name}</span>
                  {bm.baseline_score != null && <ScorePill score={bm.baseline_score} />}
                </div>
                <div className="text-slate-600 mt-0.5">{bm.artifact_type} · {bm.test_cases?.length ?? 0} cases</div>
              </button>
            ))
          }
        </Card>

        <Card title="New Benchmark">
          <div className="space-y-2">
            <input className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600" placeholder="Benchmark name" value={name} onChange={e => setName(e.target.value)} />
            <select className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white focus:outline-none" value={artType} onChange={e => setArtType(e.target.value)}>
              {['blog_post','course_outline','sales_deck','rfp_response','summary','report'].map(t => <option key={t} value={t}>{t}</option>)}
            </select>
            <input className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600" placeholder="First test case topic" value={caseTopic} onChange={e => setCaseTopic(e.target.value)} />
            <button onClick={handleCreate} disabled={creating || !name.trim() || !caseTopic.trim()} className="w-full px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded">{creating ? 'Creating…' : 'Create'}</button>
          </div>
        </Card>
      </div>

      <div className="space-y-4">
        {selected && (() => {
          const bm = benchmarks.find(b => b.id === selected)
          const bmRuns = runs.filter(r => r.benchmark_id === selected)
          return (
            <>
              <div className="flex items-center gap-3">
                <h3 className="text-sm font-medium text-white">{bm?.name}</h3>
                <button
                  onClick={() => handleRun(selected)}
                  disabled={running === selected}
                  className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
                >
                  {running === selected ? 'Running…' : 'Run Now'}
                </button>
              </div>

              {bmRuns.length === 0
                ? <p className="text-xs text-slate-500">No runs yet.</p>
                : bmRuns.map(run => (
                  <Card key={run.id} title={`Run ${run.started_at?.slice(0, 19).replace('T', ' ')} — ${run.status}`}>
                    <div className="space-y-3">
                      <div className="flex gap-6 text-xs">
                        <span>Avg score: <span className={run.status === 'regressed' ? 'text-red-400' : 'text-emerald-400'}>{run.avg_score?.toFixed(3) ?? '—'}</span></span>
                        <span>Baseline: <span className="text-slate-300">{run.baseline_score?.toFixed(3) ?? '—'}</span></span>
                        {run.delta != null && <span>Δ: <span className={run.delta < 0 ? 'text-red-400' : 'text-emerald-400'}>{run.delta > 0 ? '+' : ''}{run.delta.toFixed(3)}</span></span>}
                        <span className={STATUS_COLORS[run.status] ?? 'text-slate-400'}>{run.status}</span>
                      </div>
                      <table className="w-full text-xs">
                        <thead><tr className="text-slate-500 border-b border-[#1f2937]"><th className="text-left py-1 font-normal">Topic</th><th className="text-left py-1 font-normal">Score</th><th className="text-left py-1 font-normal">Pass</th></tr></thead>
                        <tbody>
                          {(run.case_results ?? []).map((c, i) => (
                            <tr key={i} className="border-b border-[#1f2937]/40">
                              <td className="py-1.5 text-slate-300 max-w-xs truncate">{c.topic}</td>
                              <td className="py-1.5"><ScorePill score={c.eval_score} /></td>
                              <td className="py-1.5">{c.passed ? <span className="text-emerald-400">✓</span> : <span className="text-red-400">✗</span>}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </Card>
                ))
              }
            </>
          )
        })()}
        {!selected && <p className="text-xs text-slate-500 pt-10 text-center">Select a benchmark to see runs</p>}
      </div>
    </div>
  )
}

// ── Shared components ─────────────────────────────────────────────────────────

function ScorePill({ score }: { score: number }) {
  const color = score >= 0.80 ? 'text-emerald-400' : score >= 0.65 ? 'text-amber-400' : 'text-red-400'
  return <span className={`font-mono font-medium text-xs ${color}`}>{score.toFixed(2)}</span>
}

function WeightBars({ weights, highlight = false }: { weights: Record<string, number>; highlight?: boolean }) {
  return (
    <div className="space-y-1">
      {Object.entries(weights).map(([k, v]) => (
        <div key={k} className="flex items-center gap-2">
          <span className="w-16 text-slate-500 capitalize">{k}</span>
          <div className="flex-1 bg-[#0d1117] rounded-full h-1.5">
            <div
              className={`h-1.5 rounded-full ${highlight ? 'bg-indigo-500' : 'bg-slate-600'}`}
              style={{ width: `${Math.round(v * 100)}%` }}
            />
          </div>
          <span className={`text-[10px] w-8 text-right ${highlight ? 'text-indigo-300' : 'text-slate-500'}`}>{Math.round(v * 100)}%</span>
        </div>
      ))}
    </div>
  )
}
