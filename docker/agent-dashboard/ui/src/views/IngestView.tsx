import { useEffect, useRef, useState } from 'react'
import { api, type KnowledgeBase } from '../api'
import Card from '../components/Card'

type IngestTab = 'text' | 'file'
type Strategy = 'paragraph' | 'sentence' | 'fixed'

interface IngestResult {
  kb_id: string
  chunks_stored: number
  chunks_skipped: number
  source_label: string
}

interface PreviewChunk {
  seq: number
  content: string
  char_count: number
}

const STRATEGY_LABELS: Record<Strategy, string> = {
  paragraph: 'Paragraph — split on blank lines',
  sentence:  'Sentence  — split on sentence boundaries',
  fixed:     'Fixed     — sliding window',
}

export function IngestView() {
  const [kbs, setKbs]               = useState<KnowledgeBase[]>([])
  const [selectedKb, setSelectedKb] = useState<string>('')
  const [tab, setTab]               = useState<IngestTab>('text')

  // Text tab state
  const [text, setText]             = useState('')
  const [sourceLabel, setSourceLabel] = useState('')
  const [strategy, setStrategy]     = useState<Strategy>('paragraph')
  const [chunkSize, setChunkSize]   = useState(800)
  const [overlap, setOverlap]       = useState(100)
  const [previewing, setPreviewing] = useState(false)
  const [preview, setPreview]       = useState<PreviewChunk[] | null>(null)
  const [ingesting, setIngesting]   = useState(false)
  const [result, setResult]         = useState<IngestResult | null>(null)
  const [error, setError]           = useState<string | null>(null)

  // File tab state
  const [file, setFile]             = useState<File | null>(null)
  const [fileLabel, setFileLabel]   = useState('')
  const [fileStrategy, setFileStrategy] = useState<Strategy>('paragraph')
  const [fileChunkSize, setFileChunkSize] = useState(800)
  const [uploading, setUploading]   = useState(false)
  const [fileResult, setFileResult] = useState<IngestResult | null>(null)
  const [fileError, setFileError]   = useState<string | null>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    api.listKnowledgeBases().then(list => {
      setKbs(list)
      if (list.length > 0) setSelectedKb(list[0].id)
    }).catch(() => {})
  }, [])

  // ── Text tab ──────────────────────────────────────────────────────────────

  async function handlePreview() {
    if (!text.trim()) return
    setPreviewing(true)
    setPreview(null)
    try {
      const res = await api.previewChunks(text, strategy, chunkSize, overlap)
      setPreview(res.chunks)
    } catch { setError('Preview failed') }
    setPreviewing(false)
  }

  async function handleIngestText() {
    if (!selectedKb || !text.trim()) return
    setIngesting(true)
    setError(null)
    setResult(null)
    try {
      const res = await api.ingestText(selectedKb, {
        text, source_label: sourceLabel, strategy,
        chunk_size: chunkSize, chunk_overlap: overlap,
      })
      setResult(res)
      setPreview(null)
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Ingest failed')
    }
    setIngesting(false)
  }

  // ── File tab ──────────────────────────────────────────────────────────────

  async function handleUpload() {
    if (!selectedKb || !file) return
    setUploading(true)
    setFileError(null)
    setFileResult(null)
    try {
      const res = await api.ingestFile(selectedKb, file, {
        source_label: fileLabel || file.name,
        strategy: fileStrategy,
        chunk_size: fileChunkSize,
      })
      setFileResult(res)
      setFile(null)
      if (fileRef.current) fileRef.current.value = ''
    } catch (e: unknown) {
      setFileError(e instanceof Error ? e.message : 'Upload failed')
    }
    setUploading(false)
  }

  const selectedKbName = kbs.find(k => k.id === selectedKb)?.name || ''

  return (
    <div className="space-y-4">
      {/* KB Selector */}
      <Card title="Target Knowledge Base">
        {kbs.length === 0
          ? <p className="text-xs text-slate-500">No knowledge bases yet — create one in the Generator view.</p>
          : (
            <div className="flex flex-wrap gap-2">
              {kbs.map(kb => (
                <button
                  key={kb.id}
                  onClick={() => setSelectedKb(kb.id)}
                  className={`px-3 py-1.5 rounded border text-xs transition-colors ${
                    selectedKb === kb.id
                      ? 'border-indigo-600 bg-indigo-900/30 text-white'
                      : 'border-[#1f2937] text-slate-400 hover:border-slate-600'
                  }`}
                >
                  {kb.name}
                  <span className="ml-1.5 text-slate-600">{kb.chunk_count} chunks</span>
                </button>
              ))}
            </div>
          )
        }
      </Card>

      {selectedKb && (
        <>
          {/* Tabs */}
          <div className="flex gap-1">
            {(['text', 'file'] as IngestTab[]).map(t => (
              <button
                key={t}
                onClick={() => setTab(t)}
                className={`px-3 py-1.5 text-xs rounded transition-colors ${
                  tab === t ? 'bg-indigo-800 text-indigo-200' : 'text-slate-500 hover:text-slate-300'
                }`}
              >
                {t === 'text' ? 'Paste Text' : 'Upload File'}
              </button>
            ))}
          </div>

          {tab === 'text' && (
            <div className="grid grid-cols-[1fr_300px] gap-5">
              {/* Left: text input */}
              <div className="space-y-3">
                <textarea
                  className="w-full h-64 bg-[#0d1117] border border-[#1f2937] rounded px-3 py-2 text-xs text-slate-200 placeholder-slate-600 font-mono resize-y focus:outline-none focus:border-indigo-600"
                  placeholder="Paste your document content here…"
                  value={text}
                  onChange={e => { setText(e.target.value); setPreview(null); setResult(null) }}
                />
                <input
                  className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-3 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
                  placeholder="Source label (e.g. Q3 Report, docs/overview.md)"
                  value={sourceLabel}
                  onChange={e => setSourceLabel(e.target.value)}
                />
                <div className="flex gap-2">
                  <button
                    onClick={handlePreview}
                    disabled={previewing || !text.trim()}
                    className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 disabled:opacity-40 text-slate-200 text-xs rounded"
                  >
                    {previewing ? 'Previewing…' : 'Preview Chunks'}
                  </button>
                  <button
                    onClick={handleIngestText}
                    disabled={ingesting || !text.trim()}
                    className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
                  >
                    {ingesting ? 'Ingesting…' : `Ingest into "${selectedKbName}"`}
                  </button>
                </div>

                {error && <p className="text-xs text-red-400">{error}</p>}

                {result && (
                  <div className="bg-emerald-950/30 border border-emerald-800/40 rounded p-3 text-xs space-y-0.5">
                    <p className="text-emerald-400 font-medium">Ingestion complete</p>
                    <p className="text-slate-400">{result.chunks_stored} chunks stored · {result.chunks_skipped} skipped</p>
                    {result.source_label && <p className="text-slate-500">Source: {result.source_label}</p>}
                  </div>
                )}

                {/* Chunk preview */}
                {preview && (
                  <div className="space-y-2">
                    <p className="text-xs text-slate-500">{preview.length} chunks preview:</p>
                    <div className="space-y-1.5 max-h-80 overflow-y-auto pr-1">
                      {preview.map(c => (
                        <div key={c.seq} className="bg-[#0d1117] border border-[#1f2937] rounded p-2">
                          <div className="flex justify-between mb-1">
                            <span className="text-[10px] text-indigo-500">Chunk {c.seq + 1}</span>
                            <span className="text-[10px] text-slate-600">{c.char_count} chars</span>
                          </div>
                          <p className="text-[11px] text-slate-400 font-mono leading-relaxed line-clamp-3">
                            {c.content}
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Right: settings */}
              <ChunkSettings
                strategy={strategy} onStrategy={setStrategy}
                chunkSize={chunkSize} onChunkSize={setChunkSize}
                overlap={overlap} onOverlap={setOverlap}
              />
            </div>
          )}

          {tab === 'file' && (
            <div className="grid grid-cols-[1fr_300px] gap-5">
              <div className="space-y-3">
                <div
                  className="border-2 border-dashed border-[#1f2937] hover:border-indigo-800 rounded-lg p-8 text-center cursor-pointer transition-colors"
                  onClick={() => fileRef.current?.click()}
                >
                  {file
                    ? (
                      <div>
                        <p className="text-sm text-white">{file.name}</p>
                        <p className="text-xs text-slate-500 mt-1">{(file.size / 1024).toFixed(1)} KB</p>
                      </div>
                    )
                    : (
                      <>
                        <p className="text-sm text-slate-400">Click to select a file</p>
                        <p className="text-xs text-slate-600 mt-1">.txt · .md · .csv · .json (max 5 MB)</p>
                      </>
                    )
                  }
                  <input
                    ref={fileRef}
                    type="file"
                    accept=".txt,.md,.csv,.json,.rst,.log"
                    className="hidden"
                    onChange={e => {
                      const f = e.target.files?.[0]
                      if (f) { setFile(f); setFileResult(null) }
                    }}
                  />
                </div>

                <input
                  className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-3 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
                  placeholder="Source label (defaults to filename)"
                  value={fileLabel}
                  onChange={e => setFileLabel(e.target.value)}
                />

                <button
                  onClick={handleUpload}
                  disabled={uploading || !file}
                  className="px-4 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
                >
                  {uploading ? 'Uploading…' : `Upload into "${selectedKbName}"`}
                </button>

                {fileError && <p className="text-xs text-red-400">{fileError}</p>}

                {fileResult && (
                  <div className="bg-emerald-950/30 border border-emerald-800/40 rounded p-3 text-xs space-y-0.5">
                    <p className="text-emerald-400 font-medium">Upload complete</p>
                    <p className="text-slate-400">{fileResult.chunks_stored} chunks stored · {fileResult.chunks_skipped} skipped</p>
                    <p className="text-slate-500">Source: {fileResult.source_label}</p>
                  </div>
                )}
              </div>

              <ChunkSettings
                strategy={fileStrategy} onStrategy={setFileStrategy}
                chunkSize={fileChunkSize} onChunkSize={setFileChunkSize}
                overlap={100} onOverlap={() => {}}
              />
            </div>
          )}
        </>
      )}
    </div>
  )
}

// ── Chunk Settings panel ──────────────────────────────────────────────────────

function ChunkSettings({
  strategy, onStrategy, chunkSize, onChunkSize, overlap, onOverlap,
}: {
  strategy: Strategy; onStrategy: (s: Strategy) => void
  chunkSize: number; onChunkSize: (n: number) => void
  overlap: number; onOverlap: (n: number) => void
}) {
  return (
    <div className="bg-[#0d1117] border border-[#1f2937] rounded p-3 space-y-3 self-start">
      <p className="text-xs font-medium text-slate-400">Chunking settings</p>

      <div className="space-y-1">
        <label className="text-[10px] text-slate-500">Strategy</label>
        {(Object.keys(STRATEGY_LABELS) as Strategy[]).map(s => (
          <button
            key={s}
            onClick={() => onStrategy(s)}
            className={`w-full text-left px-2 py-1.5 rounded text-xs transition-colors ${
              strategy === s ? 'bg-indigo-900/40 text-indigo-300' : 'text-slate-500 hover:text-slate-300'
            }`}
          >
            <span className="font-mono capitalize">{s}</span>
          </button>
        ))}
      </div>

      <div className="space-y-1">
        <label className="text-[10px] text-slate-500">Chunk size (chars)</label>
        <div className="flex items-center gap-2">
          <input
            type="range" min={100} max={4000} step={100}
            value={chunkSize}
            onChange={e => onChunkSize(Number(e.target.value))}
            className="flex-1 accent-indigo-500"
          />
          <span className="text-xs text-slate-400 w-10 text-right">{chunkSize}</span>
        </div>
      </div>

      {strategy !== 'paragraph' && (
        <div className="space-y-1">
          <label className="text-[10px] text-slate-500">Overlap (chars)</label>
          <div className="flex items-center gap-2">
            <input
              type="range" min={0} max={400} step={50}
              value={overlap}
              onChange={e => onOverlap(Number(e.target.value))}
              className="flex-1 accent-indigo-500"
            />
            <span className="text-xs text-slate-400 w-10 text-right">{overlap}</span>
          </div>
        </div>
      )}

      <div className="pt-1 text-[10px] text-slate-600 space-y-0.5">
        <p><span className="text-slate-500">Paragraph</span> — best for structured docs</p>
        <p><span className="text-slate-500">Sentence</span>   — best for narrative text</p>
        <p><span className="text-slate-500">Fixed</span>      — best for dense/code content</p>
      </div>
    </div>
  )
}
