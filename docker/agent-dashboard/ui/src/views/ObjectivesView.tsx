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
              className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-md bg-accent-strong hover:bg-accent text-white transition-colors"
            >
              {showForm ? <X size={12} /> : <Plus size={12} />}
              {showForm ? 'Cancel' : 'New Objective'}
            </button>
          }
        />

        {showForm && (
          <div className="mb-4 p-4 rounded-lg bg-field/40 border border-line space-y-3">
            <div>
              <label className="text-xs text-muted block mb-1">Title</label>
              <input
                className="w-full bg-field/70 border border-line rounded-lg px-3 py-2 text-sm text-ink focus:outline-none focus:border-accent transition-colors"
                placeholder="Objective title..."
                value={form.title}
                onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                onKeyDown={e => e.key === 'Enter' && create()}
              />
            </div>
            <div>
              <label className="text-xs text-muted block mb-1">Type</label>
              <select
                className="bg-field/70 border border-line rounded-lg px-3 py-2 text-sm text-ink focus:outline-none focus:border-accent transition-colors"
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
              className="text-xs px-4 py-2 rounded-lg bg-accent-strong hover:bg-accent disabled:opacity-40 text-white font-medium transition-colors"
            >
              {creating ? 'Creating...' : 'Create'}
            </button>
          </div>
        )}

        {loading && <div className="text-faint text-sm animate-pulse">Loading...</div>}

        {!loading && objectives.length === 0 && (
          <div className="text-center py-8 text-faint text-sm">
            No objectives yet. Create one to get started.
          </div>
        )}

        {!loading && objectives.length > 0 && (
          <div className="space-y-2">
            {objectives.map(obj => (
              <div
                key={obj.id}
                className="flex items-center justify-between p-3 rounded-lg bg-field/40 border border-line hover:border-line-strong hover:bg-raised/40 transition-colors"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm font-medium text-ink truncate">{obj.title}</span>
                    <Badge label={obj.status} variant={statusVariant(obj.status)} />
                  </div>
                  <div className="flex items-center gap-3 text-xs text-faint">
                    <span>{obj.objective_type}</span>
                    <span>{new Date(obj.created_at).toLocaleDateString()}</span>
                    <span className="font-mono text-faint truncate max-w-32">{obj.id}</span>
                  </div>
                </div>
                <button
                  onClick={() => run(obj.id)}
                  disabled={running === obj.id || obj.status === 'running'}
                  className="ml-3 flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg bg-accent/15 hover:bg-accent-strong disabled:opacity-40 text-accent hover:text-white ring-1 ring-accent/30 hover:ring-accent transition-colors"
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
