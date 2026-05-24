import { useEffect, useState } from 'react'
import { api, type Objective } from '../api'
import { Card, CardHeader } from '../components/Card'
import { Badge, statusVariant } from '../components/Badge'
import {
  AlertTriangle, CheckCircle2, ChevronRight, Circle,
  RefreshCw, ShieldAlert, ShieldCheck, ThumbsDown, ThumbsUp, Zap
} from 'lucide-react'

interface Readiness {
  objective_id: string
  ready: boolean
  score: number
  gates: Record<string, boolean>
  hard_blocked: string[]
  computed_at: string
}

interface Approval {
  objective_id: string
  status: 'pending' | 'approved' | 'rejected' | 'none'
  requested_by?: string
  reviewed_by?: string
  notes?: string
  requested_at?: string
  reviewed_at?: string
}

interface Maturity {
  objective_id: string
  score: number
  level: string
  gates: Record<string, boolean>
}

const GATE_META: Record<string, { label: string; hard?: boolean; description: string }> = {
  has_artifacts:    { label: 'Artifacts produced',   description: 'At least one artifact linked to this objective' },
  eval_passed:      { label: 'Eval passed',           description: 'Most recent CLEAR eval composite ≥ threshold' },
  trust_passed:     { label: 'Trust passed',          description: 'Trust score ≥ 0.65' },
  source_grounded:  { label: 'Source grounded', hard: true, description: 'Provenance recorded with traceable source refs — required for every release' },
  maturity_capable: { label: 'Maturity ≥ capable',   description: 'Maturity score ≥ 0.60 (capable level)' },
  approved:         { label: 'Human approved',   hard: true, description: 'Explicit human approval decision recorded' },
}

const LEVEL_COLOR: Record<string, string> = {
  initial:    'text-slate-400',
  developing: 'text-amber-400',
  capable:    'text-indigo-400',
  optimising: 'text-emerald-400',
}

export function ReadinessView() {
  const [objectives, setObjectives] = useState<Objective[]>([])
  const [selected, setSelected] = useState<string | null>(null)
  const [readiness, setReadiness] = useState<Readiness | null>(null)
  const [maturity, setMaturity] = useState<Maturity | null>(null)
  const [approval, setApproval] = useState<Approval | null>(null)
  const [loading, setLoading] = useState(false)
  const [reviewing, setReviewing] = useState(false)
  const [reviewerName, setReviewerName] = useState('')
  const [reviewNotes, setReviewNotes] = useState('')

  useEffect(() => { api.listObjectives().then(setObjectives) }, [])

  async function load(objectiveId: string) {
    setLoading(true)
    try {
      const [r, m, a] = await Promise.all([
        fetch(`/api/maturity/objectives/${objectiveId}/readiness`).then(r => r.json()),
        fetch(`/api/maturity/objectives/${objectiveId}`).then(r => r.json()),
        fetch(`/api/maturity/objectives/${objectiveId}/approval`).then(r => r.json()),
      ])
      setReadiness(r)
      setMaturity(m)
      setApproval(a)
    } finally {
      setLoading(false)
    }
  }

  async function assess(objectiveId: string) {
    await fetch(`/api/maturity/objectives/${objectiveId}/assess`, { method: 'POST' })
    await load(objectiveId)
  }

  async function decide(decision: 'approved' | 'rejected') {
    if (!selected) return
    await fetch(`/api/maturity/objectives/${selected}/approve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ decision, reviewed_by: reviewerName || 'reviewer', notes: reviewNotes }),
    })
    setReviewing(false)
    setReviewNotes('')
    await load(selected)
  }

  async function requestApproval() {
    if (!selected) return
    await fetch(`/api/maturity/objectives/${selected}/approve/request`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ requested_by: 'dashboard' }),
    })
    await load(selected)
  }

  function select(id: string) {
    setSelected(id)
    setReadiness(null)
    setMaturity(null)
    setApproval(null)
    setReviewing(false)
    load(id)
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {/* Objectives */}
      <Card className="md:col-span-1 self-start">
        <CardHeader title="Objectives" />
        <div className="space-y-1">
          {objectives.map(obj => (
            <button key={obj.id} onClick={() => select(obj.id)}
              className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
                selected === obj.id
                  ? 'bg-indigo-900/40 text-indigo-300 border border-indigo-700'
                  : 'text-slate-300 hover:bg-[#1a2233] border border-transparent'
              }`}
            >
              <div className="font-medium truncate">{obj.title}</div>
              <div className="flex items-center gap-1.5 mt-0.5">
                <Badge label={obj.status} variant={statusVariant(obj.status)} />
              </div>
            </button>
          ))}
        </div>
      </Card>

      {/* Gates + Approval */}
      <div className="md:col-span-2 space-y-4">
        {!selected && (
          <Card>
            <div className="text-center py-10 text-slate-500 text-sm">
              Select an objective to view its release readiness.
            </div>
          </Card>
        )}

        {selected && (
          <>
            {/* Readiness */}
            <Card>
              <CardHeader
                title="Release Readiness"
                action={
                  <button onClick={() => load(selected)} disabled={loading}
                    className="flex items-center gap-1 text-xs px-3 py-1 rounded bg-[#1a2233] text-slate-400 hover:text-slate-200 border border-[#2d3748] transition-colors disabled:opacity-40">
                    <RefreshCw size={11} className={loading ? 'animate-spin' : ''} /> Recompute
                  </button>
                }
              />

              {loading && <div className="text-slate-500 text-sm animate-pulse">Computing...</div>}

              {readiness && (
                <>
                  <div className="flex items-center gap-3 mb-5">
                    {readiness.ready
                      ? <ShieldCheck size={28} className="text-emerald-400" />
                      : <ShieldAlert size={28} className="text-red-400" />
                    }
                    <div>
                      <div className={`text-lg font-semibold ${readiness.ready ? 'text-emerald-400' : 'text-red-400'}`}>
                        {readiness.ready ? 'Ready for release' : 'Not ready'}
                      </div>
                      <div className="text-xs text-slate-500">
                        Score {(readiness.score * 100).toFixed(0)}%
                        {readiness.hard_blocked.length > 0 && (
                          <span className="ml-2 text-red-400">
                            · {readiness.hard_blocked.length} hard gate{readiness.hard_blocked.length > 1 ? 's' : ''} blocked
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2">
                    {Object.entries(readiness.gates).map(([gate, passed]) => {
                      const meta = GATE_META[gate] ?? { label: gate, description: '' }
                      return (
                        <div key={gate} className={`flex items-start gap-3 p-2.5 rounded-lg border ${
                          passed ? 'border-emerald-900/40 bg-emerald-900/10'
                                 : meta.hard ? 'border-red-900/60 bg-red-900/10'
                                             : 'border-[#1f2937] bg-[#0d1117]'
                        }`}>
                          <div className="mt-0.5">
                            {passed
                              ? <CheckCircle2 size={15} className="text-emerald-400" />
                              : meta.hard
                                ? <AlertTriangle size={15} className="text-red-400" />
                                : <Circle size={15} className="text-slate-600" />
                            }
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className={`text-sm font-medium ${passed ? 'text-slate-200' : 'text-slate-400'}`}>
                                {meta.label}
                              </span>
                              {meta.hard && <Badge label="hard gate" variant={passed ? 'green' : 'red'} />}
                            </div>
                            <div className="text-xs text-slate-600 mt-0.5">{meta.description}</div>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </>
              )}
            </Card>

            {/* Maturity */}
            {maturity && maturity.score !== undefined && (
              <Card>
                <CardHeader
                  title="Maturity Assessment"
                  action={
                    <button onClick={() => assess(selected)}
                      className="flex items-center gap-1 text-xs px-3 py-1 rounded bg-indigo-900/40 text-indigo-400 hover:bg-indigo-900/60 border border-indigo-800 transition-colors">
                      <Zap size={11} /> Assess
                    </button>
                  }
                />
                <div className="flex items-center gap-4 mb-3">
                  <div>
                    <div className={`text-2xl font-bold ${LEVEL_COLOR[maturity.level] ?? 'text-slate-400'}`}>
                      {maturity.level}
                    </div>
                    <div className="text-xs text-slate-500">{(maturity.score * 100).toFixed(0)}% score</div>
                  </div>
                  <div className="flex-1 bg-[#1f2937] rounded-full h-2">
                    <div
                      className="h-2 rounded-full bg-indigo-500 transition-all"
                      style={{ width: `${maturity.score * 100}%` }}
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-1.5">
                  {Object.entries(maturity.gates || {}).map(([gate, passed]) => (
                    <div key={gate} className="flex items-center gap-1.5 text-xs">
                      {passed
                        ? <CheckCircle2 size={12} className="text-emerald-400" />
                        : <Circle size={12} className="text-slate-600" />
                      }
                      <span className={passed ? 'text-slate-300' : 'text-slate-600'}>
                        {gate.replace(/_/g, ' ')}
                      </span>
                    </div>
                  ))}
                </div>
              </Card>
            )}

            {/* Approval */}
            <Card>
              <CardHeader title="Human Approval" />

              {approval && approval.status !== 'none' && (
                <div className={`flex items-center gap-3 p-3 rounded-lg border mb-3 ${
                  approval.status === 'approved' ? 'border-emerald-800 bg-emerald-900/10'
                  : approval.status === 'rejected' ? 'border-red-800 bg-red-900/10'
                  : 'border-amber-800 bg-amber-900/10'
                }`}>
                  {approval.status === 'approved' && <ThumbsUp size={16} className="text-emerald-400" />}
                  {approval.status === 'rejected' && <ThumbsDown size={16} className="text-red-400" />}
                  {approval.status === 'pending' && <ChevronRight size={16} className="text-amber-400" />}
                  <div>
                    <div className="text-sm font-medium text-slate-200 capitalize">{approval.status}</div>
                    {approval.reviewed_by && (
                      <div className="text-xs text-slate-500">by {approval.reviewed_by}</div>
                    )}
                    {approval.notes && (
                      <div className="text-xs text-slate-400 italic mt-0.5">"{approval.notes}"</div>
                    )}
                  </div>
                </div>
              )}

              {(!approval || approval.status === 'none') && (
                <button onClick={requestApproval}
                  className="text-xs px-4 py-2 rounded bg-indigo-600 hover:bg-indigo-500 text-white transition-colors mb-3">
                  Request Approval
                </button>
              )}

              {approval?.status === 'pending' && !reviewing && (
                <button onClick={() => setReviewing(true)}
                  className="text-xs px-4 py-2 rounded bg-amber-600 hover:bg-amber-500 text-white transition-colors">
                  Review &amp; Decide
                </button>
              )}

              {reviewing && (
                <div className="space-y-3 p-3 rounded-lg bg-[#0d1117] border border-[#1f2937]">
                  <div>
                    <label className="text-xs text-slate-400 block mb-1">Reviewer name</label>
                    <input
                      className="w-full bg-[#1a2233] border border-[#2d3748] rounded px-3 py-1.5 text-sm text-slate-200 focus:outline-none focus:border-indigo-500"
                      placeholder="Your name..."
                      value={reviewerName}
                      onChange={e => setReviewerName(e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="text-xs text-slate-400 block mb-1">Notes (optional)</label>
                    <textarea
                      className="w-full bg-[#1a2233] border border-[#2d3748] rounded px-3 py-1.5 text-sm text-slate-200 focus:outline-none focus:border-indigo-500 resize-none"
                      rows={2}
                      placeholder="Review notes..."
                      value={reviewNotes}
                      onChange={e => setReviewNotes(e.target.value)}
                    />
                  </div>
                  <div className="flex gap-2">
                    <button onClick={() => decide('approved')}
                      className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-emerald-600 hover:bg-emerald-500 text-white transition-colors">
                      <ThumbsUp size={12} /> Approve
                    </button>
                    <button onClick={() => decide('rejected')}
                      className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-red-600 hover:bg-red-500 text-white transition-colors">
                      <ThumbsDown size={12} /> Reject
                    </button>
                    <button onClick={() => setReviewing(false)}
                      className="text-xs px-3 py-1.5 rounded text-slate-400 hover:text-slate-200 transition-colors">
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </Card>
          </>
        )}
      </div>
    </div>
  )
}
