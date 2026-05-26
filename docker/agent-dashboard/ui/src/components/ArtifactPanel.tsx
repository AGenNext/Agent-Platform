import { useEffect, useState } from 'react'
import { api } from '../api'

interface EvalResult {
  composite_score: number
  passed: boolean
  dimension_scores: Record<string, number>
  rationale?: string
}

interface TrustResult {
  score: number
  evidence_count: number
}

interface ProvenanceItem {
  source_ref: string
  extract?: string
}

interface ArtifactDetail {
  id: string
  title: string
  artifact_type: string
  status: string
  content_ref?: string
  payload?: Record<string, unknown>
  created_at: string
  eval?: EvalResult
  trust?: TrustResult
  provenance?: ProvenanceItem[]
}

type DetailTab = 'content' | 'eval' | 'sources'

export function ArtifactPanel({
  artifactId,
  onClose,
}: {
  artifactId: string
  onClose: () => void
}) {
  const [detail, setDetail]   = useState<ArtifactDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [tab, setTab]         = useState<DetailTab>('content')

  useEffect(() => {
    setLoading(true)
    setDetail(null)
    api.getArtifactDetail(artifactId)
      .then(setDetail)
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [artifactId])

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/40 z-40"
        onClick={onClose}
      />

      {/* Panel */}
      <div className="fixed right-0 top-0 h-full w-[560px] bg-[#0d1117] border-l border-[#1f2937] z-50 flex flex-col shadow-2xl">
        {/* Header */}
        <div className="flex items-start justify-between px-5 py-4 border-b border-[#1f2937]">
          <div className="flex-1 min-w-0 pr-4">
            {loading
              ? <div className="h-4 bg-[#1f2937] rounded w-48 animate-pulse" />
              : <>
                  <h2 className="text-sm font-semibold text-white truncate">{detail?.title}</h2>
                  <div className="flex items-center gap-2 mt-1 text-xs text-slate-500">
                    <span>{detail?.artifact_type?.replace('_', ' ')}</span>
                    <span>·</span>
                    <span>{detail?.created_at?.slice(0, 10)}</span>
                    {detail?.payload?.model && (
                      <>
                        <span>·</span>
                        <span className="font-mono text-[10px]">{String(detail.payload.model)}</span>
                      </>
                    )}
                  </div>
                </>
            }
          </div>
          <button onClick={onClose} className="text-slate-500 hover:text-slate-200 text-lg leading-none">✕</button>
        </div>

        {/* Score bar */}
        {detail?.eval && (
          <div className="px-5 py-2 border-b border-[#1f2937] flex items-center gap-4">
            <ScoreChip score={detail.eval.composite_score} label="Eval" />
            {detail.trust && <ScoreChip score={detail.trust.score} label="Trust" />}
            <span className={`text-xs ml-auto ${detail.eval.passed ? 'text-emerald-400' : 'text-red-400'}`}>
              {detail.eval.passed ? 'Passed' : 'Did not pass'}
            </span>
          </div>
        )}

        {/* Tabs */}
        <div className="flex gap-1 px-5 pt-3">
          {(['content', 'eval', 'sources'] as DetailTab[]).map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-3 py-1.5 text-xs rounded transition-colors ${
                tab === t ? 'bg-indigo-800 text-indigo-200' : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              {t.charAt(0).toUpperCase() + t.slice(1)}
              {t === 'sources' && detail?.provenance?.length
                ? ` (${detail.provenance.length})` : ''}
            </button>
          ))}
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-5 py-4">
          {loading && (
            <div className="space-y-2">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="h-3 bg-[#1f2937] rounded animate-pulse" style={{ width: `${70 + (i % 3) * 10}%` }} />
              ))}
            </div>
          )}

          {!loading && detail && (
            <>
              {tab === 'content' && (
                <ContentTab content={detail.content_ref} />
              )}

              {tab === 'eval' && detail.eval && (
                <EvalTab eval={detail.eval} />
              )}
              {tab === 'eval' && !detail.eval && (
                <p className="text-xs text-slate-500">No eval results yet.</p>
              )}

              {tab === 'sources' && (
                <SourcesTab provenance={detail.provenance ?? []} />
              )}
            </>
          )}
        </div>
      </div>
    </>
  )
}

// ── Content tab ───────────────────────────────────────────────────────────────

function ContentTab({ content }: { content?: string }) {
  if (!content) return <p className="text-xs text-slate-500">No content.</p>

  // Simple inline renderer: headings, bold, bullets
  const lines = content.split('\n')
  return (
    <div className="text-sm text-slate-200 space-y-1.5 leading-relaxed">
      {lines.map((line, i) => {
        if (/^#{1,2}\s/.test(line)) {
          return <h3 key={i} className="text-base font-semibold text-white mt-4 mb-1">{line.replace(/^#+\s/, '')}</h3>
        }
        if (/^#{3,}\s/.test(line)) {
          return <h4 key={i} className="text-sm font-medium text-slate-300 mt-3 mb-0.5">{line.replace(/^#+\s/, '')}</h4>
        }
        if (/^[-*]\s/.test(line)) {
          return (
            <div key={i} className="flex gap-2">
              <span className="text-indigo-400 mt-0.5">•</span>
              <span>{renderInline(line.slice(2))}</span>
            </div>
          )
        }
        if (/^\d+\.\s/.test(line)) {
          const match = line.match(/^(\d+)\.\s(.*)/)
          return (
            <div key={i} className="flex gap-2">
              <span className="text-slate-500 shrink-0">{match?.[1]}.</span>
              <span>{renderInline(match?.[2] ?? '')}</span>
            </div>
          )
        }
        if (line.trim() === '') return <div key={i} className="h-2" />
        return <p key={i}>{renderInline(line)}</p>
      })}
    </div>
  )
}

function renderInline(text: string): React.ReactNode {
  // Highlight [Source: X] citations and **bold**
  const parts = text.split(/(\[Source:[^\]]+\]|\*\*[^*]+\*\*)/)
  return (
    <>
      {parts.map((part, i) => {
        if (part.startsWith('[Source:')) return <span key={i} className="text-indigo-400 text-xs">{part}</span>
        if (part.startsWith('**')) return <strong key={i} className="text-white">{part.slice(2, -2)}</strong>
        return <span key={i}>{part}</span>
      })}
    </>
  )
}

// ── Eval tab ──────────────────────────────────────────────────────────────────

function EvalTab({ eval: e }: { eval: EvalResult }) {
  const dims = Object.entries(e.dimension_scores)
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <ScoreChip score={e.composite_score} label="Composite" large />
        <span className={`text-xs ${e.passed ? 'text-emerald-400' : 'text-red-400'}`}>
          {e.passed ? '✓ Passed eval threshold' : '✗ Below eval threshold'}
        </span>
      </div>

      <div className="space-y-2">
        {dims.map(([dim, score]) => (
          <div key={dim} className="flex items-center gap-3">
            <span className="text-xs text-slate-500 capitalize w-28">{dim}</span>
            <div className="flex-1 bg-[#0d1117] rounded-full h-1.5">
              <div
                className={`h-1.5 rounded-full ${score >= 0.8 ? 'bg-emerald-500' : score >= 0.65 ? 'bg-amber-500' : 'bg-red-500'}`}
                style={{ width: `${Math.round(score * 100)}%` }}
              />
            </div>
            <span className={`text-xs w-8 text-right font-mono ${score >= 0.8 ? 'text-emerald-400' : score >= 0.65 ? 'text-amber-400' : 'text-red-400'}`}>
              {score.toFixed(2)}
            </span>
          </div>
        ))}
      </div>

      {e.rationale && (
        <p className="text-xs text-slate-500 italic border-l border-[#1f2937] pl-3">{e.rationale}</p>
      )}
    </div>
  )
}

// ── Sources tab ───────────────────────────────────────────────────────────────

function SourcesTab({ provenance }: { provenance: ProvenanceItem[] }) {
  if (provenance.length === 0) {
    return <p className="text-xs text-slate-500">No source provenance recorded.</p>
  }

  // Deduplicate by source_ref
  const seen = new Set<string>()
  const unique = provenance.filter(p => {
    if (seen.has(p.source_ref)) return false
    seen.add(p.source_ref)
    return true
  })

  return (
    <div className="space-y-3">
      <p className="text-xs text-slate-500">{unique.length} source{unique.length !== 1 ? 's' : ''} used</p>
      {unique.map((p, i) => (
        <div key={i} className="bg-[#0a0f16] border border-[#1f2937] rounded p-3 space-y-1">
          <p className="text-xs font-medium text-indigo-300">{p.source_ref}</p>
          {p.extract && (
            <p className="text-[11px] text-slate-500 line-clamp-3">{p.extract}</p>
          )}
        </div>
      ))}
    </div>
  )
}

// ── Shared ────────────────────────────────────────────────────────────────────

function ScoreChip({ score, label, large = false }: { score: number; label: string; large?: boolean }) {
  const color = score >= 0.80 ? 'text-emerald-400' : score >= 0.65 ? 'text-amber-400' : 'text-red-400'
  return (
    <div className="flex flex-col items-center">
      <span className={`font-mono font-bold ${large ? 'text-2xl' : 'text-sm'} ${color}`}>{score.toFixed(2)}</span>
      <span className="text-[10px] text-slate-500">{label}</span>
    </div>
  )
}
