import { useEffect, useState } from 'react'
import { api, type Artifact, type EvalResult, type TrustScore } from '../api'
import { Card, CardHeader } from '../components/Card'
import { Badge, statusVariant } from '../components/Badge'
import { ChevronDown, ChevronRight, ShieldCheck, Star } from 'lucide-react'

export function ArtifactsView() {
  const [artifacts, setArtifacts] = useState<Artifact[]>([])
  const [loading, setLoading] = useState(true)
  const [expanded, setExpanded] = useState<string | null>(null)

  useEffect(() => {
    api.listArtifacts()
      .then(setArtifacts)
      .finally(() => setLoading(false))
  }, [])

  return (
    <Card>
      <CardHeader title="Artifacts" />

      {loading && <div className="text-slate-500 text-sm animate-pulse">Loading...</div>}

      {!loading && artifacts.length === 0 && (
        <div className="text-center py-8 text-slate-500 text-sm">
          No artifacts yet. Run an objective to generate artifacts.
        </div>
      )}

      {!loading && artifacts.length > 0 && (
        <div className="space-y-2">
          {artifacts.map(artifact => (
            <div key={artifact.id} className="rounded-lg bg-[#0d1117] border border-[#1f2937]">
              <button
                onClick={() => setExpanded(e => e === artifact.id ? null : artifact.id)}
                className="w-full flex items-center justify-between p-3 text-left hover:bg-[#131b2a] transition-colors rounded-lg"
              >
                <div className="flex items-center gap-2 min-w-0">
                  {expanded === artifact.id ? <ChevronDown size={14} className="text-slate-500 shrink-0" /> : <ChevronRight size={14} className="text-slate-500 shrink-0" />}
                  <span className="text-sm font-medium text-slate-200 truncate">{artifact.title}</span>
                  <Badge label={artifact.artifact_type} variant="blue" />
                  <Badge label={artifact.status} variant={statusVariant(artifact.status)} />
                </div>
                <span className="text-xs text-slate-500 ml-3 shrink-0">
                  {new Date(artifact.created_at).toLocaleDateString()}
                </span>
              </button>

              {expanded === artifact.id && (
                <div className="px-3 pb-3 space-y-3">
                  <div className="text-xs text-slate-500 font-mono border-t border-[#1f2937] pt-3">
                    ID: {artifact.id}<br />
                    Objective: {artifact.objective_id}
                    {artifact.content_ref && <><br />Ref: {artifact.content_ref}</>}
                  </div>
                  <ArtifactEval artifactId={artifact.id} />
                  <ArtifactTrust artifactId={artifact.id} />
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </Card>
  )
}

function ArtifactEval({ artifactId }: { artifactId: string }) {
  const [result, setResult] = useState<EvalResult | null>(null)

  useEffect(() => {
    api.evalResult(artifactId).then(setResult).catch(() => setResult(null))
  }, [artifactId])

  if (!result) return null

  return (
    <div className="p-2 rounded bg-[#111827] border border-[#1f2937]">
      <div className="flex items-center gap-2 mb-2">
        <Star size={12} className="text-amber-400" />
        <span className="text-xs font-medium text-slate-300">CLEAR Eval</span>
        <Badge label={result.passed ? 'passed' : 'failed'} variant={result.passed ? 'green' : 'red'} />
        <span className="text-xs text-slate-400 ml-auto">{(result.composite_score * 100).toFixed(0)}%</span>
      </div>
      <div className="grid grid-cols-5 gap-1">
        {Object.entries(result.dimension_scores).map(([dim, score]) => (
          <div key={dim} className="text-center">
            <div className="text-xs text-slate-500 capitalize">{dim.slice(0, 4)}</div>
            <div
              className="text-xs font-semibold"
              style={{ color: score >= 0.7 ? '#10b981' : score >= 0.5 ? '#f59e0b' : '#ef4444' }}
            >
              {(score * 100).toFixed(0)}%
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

function ArtifactTrust({ artifactId }: { artifactId: string }) {
  const [trust, setTrust] = useState<TrustScore | null>(null)

  useEffect(() => {
    api.trustScore(artifactId).then(setTrust).catch(() => setTrust(null))
  }, [artifactId])

  if (!trust) return null

  return (
    <div className="p-2 rounded bg-[#111827] border border-[#1f2937]">
      <div className="flex items-center gap-2">
        <ShieldCheck size={12} className="text-indigo-400" />
        <span className="text-xs font-medium text-slate-300">Trust</span>
        <div className="flex-1 bg-[#1f2937] rounded-full h-1.5 ml-1">
          <div
            className="h-1.5 rounded-full bg-indigo-500"
            style={{ width: `${Math.min(trust.score * 100, 100)}%` }}
          />
        </div>
        <span className="text-xs text-slate-400">{(trust.score * 100).toFixed(0)}%</span>
        <span className="text-xs text-slate-500">{trust.evidence_count} links</span>
      </div>
    </div>
  )
}
