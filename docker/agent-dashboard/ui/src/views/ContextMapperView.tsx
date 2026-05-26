import { useState } from 'react'
import { api, type ContextMap, type KbContextEntry } from '../api'

export function ContextMapperView({ onOpenGenerator }: { onOpenGenerator?: (kbIds: string[]) => void }) {
  const [query, setQuery]         = useState('')
  const [loading, setLoading]     = useState(false)
  const [result, setResult]       = useState<ContextMap | null>(null)
  const [selected, setSelected]   = useState<Set<string>>(new Set())
  const [expanded, setExpanded]   = useState<string | null>(null)

  async function handleSearch() {
    if (!query.trim()) return
    setLoading(true)
    setResult(null)
    setSelected(new Set())
    try {
      const map = await api.mapContext(query)
      setResult(map)
      setSelected(new Set(map.suggested_kb_ids))
    } catch {}
    setLoading(false)
  }

  function toggleKb(kbId: string) {
    setSelected(prev => {
      const next = new Set(prev)
      next.has(kbId) ? next.delete(kbId) : next.add(kbId)
      return next
    })
  }

  return (
    <div className="space-y-5">
      {/* Search bar */}
      <div className="flex gap-2">
        <input
          className="flex-1 bg-[#0d1117] border border-[#1f2937] rounded px-3 py-2 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
          placeholder="Enter a topic or question to map relevant knowledge bases…"
          value={query}
          onChange={e => setQuery(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSearch()}
        />
        <button
          onClick={handleSearch}
          disabled={loading || !query.trim()}
          className="px-4 py-2 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-sm rounded"
        >
          {loading ? 'Mapping…' : 'Map Context'}
        </button>
      </div>

      {result && (
        <>
          {/* Summary bar */}
          <div className="flex items-center gap-4 text-xs text-slate-500">
            <span><span className="text-white">{result.kb_maps.length}</span> knowledge bases scanned</span>
            <span><span className="text-indigo-400">{result.suggested_kb_ids.length}</span> relevant</span>
            {result.cross_links.length > 0 && (
              <span><span className="text-amber-400">{result.cross_links.length}</span> cross-KB links</span>
            )}
            {selected.size > 0 && (
              <button
                onClick={() => onOpenGenerator?.(Array.from(selected))}
                className="ml-auto px-3 py-1.5 bg-emerald-800 hover:bg-emerald-700 text-emerald-200 rounded"
              >
                Open {selected.size} KB{selected.size !== 1 ? 's' : ''} in Generator →
              </button>
            )}
          </div>

          <div className="grid grid-cols-[1fr_260px] gap-5">
            {/* KB map cards */}
            <div className="space-y-2">
              {result.kb_maps.length === 0
                ? <p className="text-xs text-slate-500 pt-6 text-center">No knowledge bases found.</p>
                : result.kb_maps.map(kb => (
                  <KbCard
                    key={kb.kb_id}
                    kb={kb}
                    selected={selected.has(kb.kb_id)}
                    onToggle={() => toggleKb(kb.kb_id)}
                    expanded={expanded === kb.kb_id}
                    onExpand={() => setExpanded(expanded === kb.kb_id ? null : kb.kb_id)}
                  />
                ))
              }
            </div>

            {/* Cross-KB links panel */}
            <div className="space-y-3">
              {result.cross_links.length > 0 && (
                <div className="bg-[#0d1117] border border-[#1f2937] rounded p-3">
                  <p className="text-xs font-medium text-amber-400 mb-2">Cross-KB Entity Links</p>
                  <div className="space-y-2">
                    {result.cross_links.map((link, i) => (
                      <div key={i} className="text-xs">
                        <p className="text-white capitalize font-medium">{link.entity_name}</p>
                        <p className="text-slate-500">{link.kb_names.join(' · ')}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {result.suggested_kb_ids.length > 0 && (
                <div className="bg-[#0d1117] border border-indigo-900/50 rounded p-3">
                  <p className="text-xs font-medium text-indigo-400 mb-2">Suggested for generation</p>
                  <div className="space-y-1">
                    {result.kb_maps
                      .filter(m => result.suggested_kb_ids.includes(m.kb_id))
                      .map(m => (
                        <div key={m.kb_id} className="flex items-center justify-between text-xs">
                          <span className="text-slate-300 truncate">{m.kb_name}</span>
                          <RelevanceBar score={m.relevance_score} />
                        </div>
                      ))
                    }
                  </div>
                </div>
              )}
            </div>
          </div>
        </>
      )}

      {!result && !loading && (
        <p className="text-xs text-slate-500 pt-10 text-center">
          Enter a topic above to discover which knowledge bases contain relevant content.
        </p>
      )}
    </div>
  )
}

// ── KB Card ───────────────────────────────────────────────────────────────────

function KbCard({
  kb, selected, onToggle, expanded, onExpand,
}: {
  kb: KbContextEntry
  selected: boolean
  onToggle: () => void
  expanded: boolean
  onExpand: () => void
}) {
  const hasContent = kb.matched_entity_count + kb.matched_community_count + kb.matched_chunk_count > 0

  return (
    <div className={`border rounded transition-colors ${
      selected ? 'border-indigo-600 bg-indigo-950/20' : 'border-[#1f2937] bg-[#0d1117]'
    }`}>
      <div className="flex items-center gap-3 px-3 py-2.5">
        <input
          type="checkbox"
          checked={selected}
          onChange={onToggle}
          className="accent-indigo-500 cursor-pointer"
        />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-white truncate">{kb.kb_name}</span>
            <span className="text-[10px] text-slate-600 border border-[#1f2937] rounded px-1">{kb.kb_type}</span>
            {kb.has_graph && <span className="text-[10px] text-indigo-500 border border-indigo-900 rounded px-1">graph</span>}
          </div>
          <div className="flex items-center gap-3 mt-0.5 text-[11px] text-slate-500">
            {kb.matched_entity_count    > 0 && <span className="text-emerald-500">{kb.matched_entity_count} entities</span>}
            {kb.matched_community_count > 0 && <span className="text-indigo-400">{kb.matched_community_count} communities</span>}
            {kb.matched_chunk_count     > 0 && <span>{kb.matched_chunk_count} chunks</span>}
            {!hasContent && <span className="text-slate-600">no matches</span>}
            <span className="text-slate-600">{kb.chunk_count} total chunks</span>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <RelevanceBar score={kb.relevance_score} showLabel />
          {hasContent && (
            <button
              onClick={onExpand}
              className="text-[10px] text-slate-500 hover:text-slate-300"
            >
              {expanded ? '▲ less' : '▼ more'}
            </button>
          )}
        </div>
      </div>

      {expanded && hasContent && (
        <div className="border-t border-[#1f2937] px-3 py-2 space-y-2">
          {kb.top_communities.length > 0 && (
            <div>
              <p className="text-[10px] text-indigo-400 mb-1">Communities</p>
              {kb.top_communities.map((c, i) => (
                <div key={i} className="mb-1.5">
                  <p className="text-xs text-white">{c.title || 'Community'}</p>
                  <p className="text-[11px] text-slate-500">{c.summary}</p>
                </div>
              ))}
            </div>
          )}
          {kb.top_entities.length > 0 && (
            <div>
              <p className="text-[10px] text-emerald-500 mb-1">Matched entities</p>
              <div className="flex flex-wrap gap-1">
                {kb.top_entities.map((e, i) => (
                  <span key={i} className="text-[10px] bg-[#1a2233] text-slate-300 rounded px-1.5 py-0.5">
                    {e.name} <span className="text-slate-600">· {e.entity_type}</span>
                  </span>
                ))}
              </div>
            </div>
          )}
          {kb.top_chunks.length > 0 && (
            <div>
              <p className="text-[10px] text-slate-500 mb-1">Source excerpts</p>
              {kb.top_chunks.map((c, i) => (
                <div key={i} className="mb-1 text-[11px] text-slate-400 bg-[#0a0f16] rounded p-1.5">
                  {c.source_label && <span className="text-slate-600 mr-1">[{c.source_label}]</span>}
                  {c.preview}…
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}

// ── Shared components ─────────────────────────────────────────────────────────

function RelevanceBar({ score, showLabel = false }: { score: number; showLabel?: boolean }) {
  const pct = Math.round(score * 100)
  const color = score >= 0.6 ? 'bg-emerald-500' : score >= 0.3 ? 'bg-amber-500' : score > 0 ? 'bg-slate-600' : 'bg-[#1f2937]'
  return (
    <div className="flex items-center gap-1.5">
      {showLabel && <span className="text-[10px] text-slate-500 w-7 text-right">{pct}%</span>}
      <div className="w-16 bg-[#1f2937] rounded-full h-1.5">
        <div className={`h-1.5 rounded-full ${color}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  )
}
