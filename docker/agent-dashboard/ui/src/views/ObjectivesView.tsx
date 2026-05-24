import { useEffect, useState } from 'react'
import { api, type Objective } from '../api'
import { Card, CardHeader } from '../components/Card'
import { Badge, statusVariant } from '../components/Badge'
import { Play, Plus, X } from 'lucide-react'

export function ObjectivesView() {
  const [objectives, setObjectives] = useState<Objective[]>([])
  const [loading, setLoading] = useState(true)
  const [creating, setCreating] = useState(false)
  const [running, setRunning] = useState<string | null>(null)
  const [form, setForm] = useState({ title: '', objective_type: 'generic' })
  const [showForm, setShowForm] = useState(false)

  async function load() {
    try {
      setObjectives(await api.listObjectives())
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  async function create() {
    if (!form.title.trim()) return
    setCreating(true)
    try {
      await api.createObjective({ title: form.title, objective_type: form.objective_type })
      setForm({ title: '', objective_type: 'generic' })
      setShowForm(false)
      await load()
    } finally {
      setCreating(false)
    }
  }

  async function run(id: string) {
    setRunning(id)
    try {
      await api.runObjective(id)
      await load()
    } finally {
      setRunning(null)
    }
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title="Objectives"
          action={
            <button
              onClick={() => setShowForm(v => !v)}
              className="flex items-center gap-1.5 text-xs px-3 py-1 rounded bg-indigo-600 hover:bg-indigo-500 text-white transition-colors"
            >
              {showForm ? <X size={12} /> : <Plus size={12} />}
              {showForm ? 'Cancel' : 'New Objective'}
            </button>
          }
        />

        {showForm && (
          <div className="mb-4 p-3 rounded-lg bg-[#0d1117] border border-[#1f2937] space-y-3">
            <div>
              <label className="text-xs text-slate-400 block mb-1">Title</label>
              <input
                className="w-full bg-[#1a2233] border border-[#2d3748] rounded px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500"
                placeholder="Objective title..."
                value={form.title}
                onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                onKeyDown={e => e.key === 'Enter' && create()}
              />
            </div>
            <div>
              <label className="text-xs text-slate-400 block mb-1">Type</label>
              <select
                className="bg-[#1a2233] border border-[#2d3748] rounded px-3 py-2 text-sm text-slate-200 focus:outline-none focus:border-indigo-500"
                value={form.objective_type}
                onChange={e => setForm(f => ({ ...f, objective_type: e.target.value }))}
              >
                <option value="generic">generic</option>
                <option value="research">research</option>
                <option value="generation">generation</option>
                <option value="eval">eval</option>
              </select>
            </div>
            <button
              onClick={create}
              disabled={creating || !form.title.trim()}
              className="text-xs px-4 py-1.5 rounded bg-emerald-600 hover:bg-emerald-500 disabled:opacity-40 text-white transition-colors"
            >
              {creating ? 'Creating...' : 'Create'}
            </button>
          </div>
        )}

        {loading && <div className="text-slate-500 text-sm animate-pulse">Loading...</div>}

        {!loading && objectives.length === 0 && (
          <div className="text-center py-8 text-slate-500 text-sm">
            No objectives yet. Create one to get started.
          </div>
        )}

        {!loading && objectives.length > 0 && (
          <div className="space-y-2">
            {objectives.map(obj => (
              <div
                key={obj.id}
                className="flex items-center justify-between p-3 rounded-lg bg-[#0d1117] border border-[#1f2937] hover:border-[#374151] transition-colors"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm font-medium text-slate-200 truncate">{obj.title}</span>
                    <Badge label={obj.status} variant={statusVariant(obj.status)} />
                  </div>
                  <div className="flex items-center gap-3 text-xs text-slate-500">
                    <span>{obj.objective_type}</span>
                    <span>{new Date(obj.created_at).toLocaleDateString()}</span>
                    <span className="font-mono text-slate-600 truncate max-w-32">{obj.id}</span>
                  </div>
                </div>
                <button
                  onClick={() => run(obj.id)}
                  disabled={running === obj.id || obj.status === 'running'}
                  className="ml-3 flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-indigo-900/50 hover:bg-indigo-600 disabled:opacity-40 text-indigo-300 hover:text-white border border-indigo-700 hover:border-indigo-500 transition-colors"
                >
                  <Play size={11} />
                  {running === obj.id ? 'Starting...' : 'Run'}
                </button>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}
