import { useEffect, useState } from 'react'
import { api, type KnowledgeBase, type ArtifactJob, type GraphStats } from '../api'
import Card from '../components/Card'
import { ArtifactPanel } from '../components/ArtifactPanel'

const ARTIFACT_TYPES = [
  { id: 'blog_post',      label: 'Blog Post' },
  { id: 'course_outline', label: 'Course Outline' },
  { id: 'sales_deck',     label: 'Sales Deck Outline' },
  { id: 'rfp_response',   label: 'RFP Response' },
  { id: 'summary',        label: 'Executive Summary' },
  { id: 'report',         label: 'Research Report' },
]

const KB_TYPE_COLORS: Record<string, string> = {
  general:    'bg-slate-700 text-slate-200',
  technical:  'bg-blue-900/60 text-blue-300',
  product:    'bg-indigo-900/60 text-indigo-300',
  legal:      'bg-amber-900/60 text-amber-300',
  marketing:  'bg-pink-900/60 text-pink-300',
  research:   'bg-emerald-900/60 text-emerald-300',
}

export function GeneratorView({ prefilledKbIds }: { prefilledKbIds?: string[] }) {
  const [kbs, setKbs] = useState<KnowledgeBase[]>([])
  const [selectedKbs, setSelectedKbs] = useState<Set<string>>(
    () => new Set(prefilledKbIds ?? [])
  )
  const [artifactType, setArtifactType] = useState('blog_post')
  const [topic, setTopic] = useState('')
  const [instructions, setInstructions] = useState('')
  const [objectiveId, setObjectiveId] = useState('')
  const [running, setRunning]         = useState(false)
  const [job, setJob]                 = useState<ArtifactJob | null>(null)
  const [stepLabel, setStepLabel]     = useState<string>('')
  const [error, setError]             = useState<string | null>(null)
  const [panelArtifactId, setPanelId] = useState<string | null>(null)
  const [graphStats, setGraphStats] = useState<Record<string, GraphStats>>({})
  const [buildingGraph, setBuildingGraph] = useState<string | null>(null)

  // KB create form
  const [showCreate, setShowCreate] = useState(false)
  const [newName, setNewName] = useState('')
  const [newDesc, setNewDesc] = useState('')
  const [newType, setNewType] = useState('general')
  const [creating, setCreating] = useState(false)

  useEffect(() => { loadKbs() }, [])

  async function loadGraphStats(kbs: KnowledgeBase[]) {
    const stats: Record<string, GraphStats> = {}
    await Promise.all(kbs.map(async kb => {
      try { stats[kb.id] = await api.getGraphStats(kb.id) } catch {}
    }))
    setGraphStats(stats)
  }

  async function handleBuildGraph(kbId: string) {
    setBuildingGraph(kbId)
    try {
      await api.buildGraph(kbId)
      const updated = await api.listKnowledgeBases()
      setKbs(updated)
      await loadGraphStats(updated)
    } catch {}
    setBuildingGraph(null)
  }

  async function loadKbs() {
    try {
      const kbs = await api.listKnowledgeBases()
      setKbs(kbs)
      await loadGraphStats(kbs)
    } catch {}
  }

  function toggleKb(id: string) {
    setSelectedKbs(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  async function handleGenerate() {
    if (!topic.trim()) { setError('Topic is required'); return }
    if (selectedKbs.size === 0) { setError('Select at least one knowledge base'); return }
    setError(null)
    setRunning(true)
    setJob(null)
    setStepLabel('Queued…')

    try {
      // POST returns immediately with job_id
      const startedJob = await api.generateArtifact({
        objective_id: objectiveId || 'default',
        artifact_type: artifactType,
        kb_ids: [...selectedKbs],
        topic,
        instructions: instructions || undefined,
      })
      setJob(startedJob)

      // Stream progress via SSE
      const es = new EventSource(`/api/generate/jobs/${startedJob.id}/stream`)
      es.onmessage = (e) => {
        try {
          const data = JSON.parse(e.data)
          setStepLabel(data.step_label ?? '')
          if (data.done) {
            es.close()
            setRunning(false)
            // Refresh job record
            api.getJob(startedJob.id).then(j => {
              setJob(j)
              if (j.artifact_id) setPanelId(j.artifact_id)
            }).catch(() => {})
          }
        } catch {}
      }
      es.onerror = () => {
        es.close()
        setRunning(false)
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Generation failed')
      setRunning(false)
    }
  }

  async function handleCreateKb() {
    if (!newName.trim()) return
    setCreating(true)
    try {
      await api.createKnowledgeBase({ name: newName, description: newDesc, kb_type: newType })
      setNewName(''); setNewDesc(''); setNewType('general'); setShowCreate(false)
      await loadKbs()
    } catch {}
    setCreating(false)
  }

  const selectedTypeLabel = ARTIFACT_TYPES.find(t => t.id === artifactType)?.label ?? ''

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold text-white">Artifact Generator</h2>
          <p className="text-xs text-slate-500 mt-0.5">Select knowledge bases → generate grounded artifacts</p>
        </div>
        <button
          onClick={() => setShowCreate(v => !v)}
          className="text-xs px-3 py-1.5 rounded bg-indigo-700 hover:bg-indigo-600 text-white transition-colors"
        >
          + New KB
        </button>
      </div>

      {showCreate && (
        <Card title="Create Knowledge Base">
          <div className="space-y-3">
            <input
              className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-3 py-2 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
              placeholder="Knowledge base name"
              value={newName}
              onChange={e => setNewName(e.target.value)}
            />
            <input
              className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-3 py-2 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
              placeholder="Description (optional)"
              value={newDesc}
              onChange={e => setNewDesc(e.target.value)}
            />
            <select
              className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-indigo-600"
              value={newType}
              onChange={e => setNewType(e.target.value)}
            >
              {Object.keys(KB_TYPE_COLORS).map(t => (
                <option key={t} value={t}>{t}</option>
              ))}
            </select>
            <button
              onClick={handleCreateKb}
              disabled={creating || !newName.trim()}
              className="px-4 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-50 text-white text-sm rounded transition-colors"
            >
              {creating ? 'Creating…' : 'Create'}
            </button>
          </div>
        </Card>
      )}

      <div className="grid grid-cols-[280px_1fr] gap-6">
        {/* Left: KB selector + config */}
        <div className="space-y-4">
          <Card title={`Knowledge Bases (${kbs.length})`}>
            {kbs.length === 0 ? (
              <p className="text-xs text-slate-500">No knowledge bases yet. Create one above.</p>
            ) : (
              <div className="space-y-1.5">
                {kbs.map(kb => {
                  const selected = selectedKbs.has(kb.id)
                  return (
                    <button
                      key={kb.id}
                      onClick={() => toggleKb(kb.id)}
                      className={`w-full text-left px-3 py-2 rounded border text-xs transition-colors ${
                        selected
                          ? 'border-indigo-600 bg-indigo-900/40 text-white'
                          : 'border-[#1f2937] text-slate-400 hover:border-slate-600 hover:text-slate-200'
                      }`}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <span className="font-medium truncate">{kb.name}</span>
                        <span className={`shrink-0 px-1.5 py-0.5 rounded text-[10px] ${KB_TYPE_COLORS[kb.kb_type] ?? 'bg-slate-700 text-slate-300'}`}>
                          {kb.kb_type}
                        </span>
                      </div>
                      {kb.description && (
                        <div className="text-slate-500 mt-0.5 truncate">{kb.description}</div>
                      )}
                      <div className="flex items-center justify-between mt-0.5">
                        <span className="text-slate-600">{kb.chunk_count} chunk{kb.chunk_count !== 1 ? 's' : ''}</span>
                        {(() => {
                          const gs = graphStats[kb.id]
                          if (gs && gs.entity_count > 0) {
                            return <span className="text-[10px] text-emerald-500">{gs.entity_count}e · {gs.community_count}c</span>
                          }
                          return (
                            <button
                              onClick={e => { e.stopPropagation(); handleBuildGraph(kb.id) }}
                              disabled={buildingGraph === kb.id}
                              className="text-[10px] text-indigo-400 hover:text-indigo-300 disabled:opacity-50"
                            >
                              {buildingGraph === kb.id ? 'building…' : '+ graph'}
                            </button>
                          )
                        })()}
                      </div>
                    </button>
                  )
                })}
              </div>
            )}
          </Card>

          <Card title="Configuration">
            <div className="space-y-3">
              <div>
                <label className="text-xs text-slate-500 block mb-1">Artifact type</label>
                <select
                  className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-sm text-white focus:outline-none focus:border-indigo-600"
                  value={artifactType}
                  onChange={e => setArtifactType(e.target.value)}
                >
                  {ARTIFACT_TYPES.map(t => (
                    <option key={t.id} value={t.id}>{t.label}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs text-slate-500 block mb-1">Objective ID (optional)</label>
                <input
                  className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
                  placeholder="links artifact to objective"
                  value={objectiveId}
                  onChange={e => setObjectiveId(e.target.value)}
                />
              </div>
            </div>
          </Card>
        </div>

        {/* Right: Topic + output */}
        <div className="space-y-4">
          <Card title="Generate">
            <div className="space-y-3">
              <div>
                <label className="text-xs text-slate-500 block mb-1">Topic / question</label>
                <input
                  className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-3 py-2 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
                  placeholder="What should the artifact be about?"
                  value={topic}
                  onChange={e => setTopic(e.target.value)}
                />
              </div>
              <div>
                <label className="text-xs text-slate-500 block mb-1">Extra instructions (optional)</label>
                <textarea
                  rows={2}
                  className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-3 py-2 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600 resize-none"
                  placeholder="Tone, audience, length constraints…"
                  value={instructions}
                  onChange={e => setInstructions(e.target.value)}
                />
              </div>

              {error && <p className="text-xs text-red-400">{error}</p>}

              <div className="flex items-center gap-3">
                <button
                  onClick={handleGenerate}
                  disabled={running || selectedKbs.size === 0 || !topic.trim()}
                  className="px-5 py-2 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-sm font-medium rounded transition-colors"
                >
                  {running ? 'Generating…' : `Generate ${selectedTypeLabel}`}
                </button>
                {running && stepLabel && (
                  <span className="text-xs text-indigo-300 animate-pulse">{stepLabel}</span>
                )}
                {!running && selectedKbs.size > 0 && (
                  <span className="text-xs text-slate-500">{selectedKbs.size} KB{selectedKbs.size > 1 ? 's' : ''} selected</span>
                )}
              </div>
            </div>
          </Card>

          {job && <JobResult job={job} onView={id => setPanelId(id)} />}
        </div>
      </div>

      {panelArtifactId && (
        <ArtifactPanel
          artifactId={panelArtifactId}
          onClose={() => setPanelId(null)}
        />
      )}
    </div>
  )
}

function JobResult({ job, onView }: { job: ArtifactJob; onView: (id: string) => void }) {
  return (
    <Card title={`Result — ${job.status.toUpperCase()}`}>
      <div className="space-y-3">
        <div className="flex gap-6 text-xs text-slate-400">
          <span>Model: <span className="text-slate-200">{job.model_used ?? '—'}</span></span>
          <span>Chunks: <span className="text-slate-200">{Array.isArray(job.chunks_used) ? job.chunks_used.length : 0}</span></span>
        </div>

        {job.status === 'failed' && (
          <div className="p-3 bg-red-900/20 border border-red-800/40 rounded text-xs text-red-300">
            {job.error}
          </div>
        )}

        {job.status === 'complete' && job.artifact_id && (
          <div className="flex items-center justify-between">
            <span className="text-xs text-emerald-400">Artifact created · provenance recorded · CLEAR eval complete</span>
            <button
              onClick={() => onView(job.artifact_id!)}
              className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 text-white text-xs rounded"
            >
              View Artifact →
            </button>
          </div>
        )}
      </div>
    </Card>
  )
}
