import { useState } from 'react'
import { api, type Agent, type HandoffLink } from '../api'
import { Card, CardHeader } from '../components/Card'
import { Badge, statusVariant } from '../components/Badge'
import { ArrowRight, Bot, Search } from 'lucide-react'

export function TraceView() {
  const [runId, setRunId] = useState('')
  const [agents, setAgents] = useState<Agent[]>([])
  const [chain, setChain] = useState<HandoffLink[]>([])
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function lookup() {
    if (!runId.trim()) return
    setLoading(true)
    setError(null)
    setSelectedAgent(null)
    setChain([])
    try {
      const a = await api.listAgents(runId.trim())
      setAgents(a)
    } catch {
      setError('No agents found for this run ID')
      setAgents([])
    } finally {
      setLoading(false)
    }
  }

  async function loadChain(agent: Agent) {
    setSelectedAgent(agent)
    try {
      const c = await api.getHandoffChain(agent.id)
      setChain(c)
    } catch {
      setChain([])
    }
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader title="A2A Trace Explorer" />
        <div className="flex gap-2">
          <input
            className="flex-1 bg-surface border border-line rounded px-3 py-2 text-sm text-ink focus:outline-none focus:border-accent"
            placeholder="Paste a workflow run ID..."
            value={runId}
            onChange={e => setRunId(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && lookup()}
          />
          <button
            onClick={lookup}
            disabled={loading || !runId.trim()}
            className="flex items-center gap-1.5 px-3 py-2 rounded bg-accent-strong hover:bg-accent disabled:opacity-40 text-white text-sm transition-colors"
          >
            <Search size={14} />
            {loading ? 'Loading...' : 'Trace'}
          </button>
        </div>

        {error && (
          <div className="mt-3 text-sm text-red-400">{error}</div>
        )}
      </Card>

      {agents.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card>
            <CardHeader title={`Agents (${agents.length})`} />
            <div className="space-y-2">
              {agents.map(agent => (
                <button
                  key={agent.id}
                  onClick={() => loadChain(agent)}
                  className={`w-full flex items-center gap-3 p-3 rounded-lg border text-left transition-colors ${
                    selectedAgent?.id === agent.id
                      ? 'border-accent bg-accent/10'
                      : 'border-line bg-surface hover:border-line-strong'
                  }`}
                >
                  <div className="p-1.5 rounded bg-accent/15 text-accent">
                    <Bot size={14} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium text-ink">{agent.agent_role}</div>
                    <div className="text-xs text-faint font-mono truncate">{agent.id}</div>
                  </div>
                  <Badge label={agent.status} variant={statusVariant(agent.status)} />
                </button>
              ))}
            </div>
          </Card>

          <Card>
            <CardHeader title={selectedAgent ? `Handoff Chain — ${selectedAgent.agent_role}` : 'Handoff Chain'} />
            {!selectedAgent && (
              <div className="text-faint text-sm">Select an agent to view its handoff chain.</div>
            )}
            {selectedAgent && chain.length === 0 && (
              <div className="text-faint text-sm">No handoffs recorded for this agent.</div>
            )}
            {chain.length > 0 && (
              <div className="space-y-2">
                {chain.map((link, i) => (
                  <div key={link.id} className="relative">
                    <div className="flex items-start gap-3 p-3 rounded-lg bg-surface border border-line">
                      <div className="flex flex-col items-center">
                        <div className="text-xs text-faint font-mono mt-0.5">{i + 1}</div>
                        {i < chain.length - 1 && (
                          <div className="w-px h-6 bg-line mt-1" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 text-xs mb-1">
                          <span className="text-muted font-mono truncate max-w-24">{link.source_agent_id}</span>
                          <ArrowRight size={11} className="text-accent shrink-0" />
                          <span className="text-muted font-mono truncate max-w-24">{link.target_agent_id}</span>
                        </div>
                        {link.context && (
                          <div className="text-xs text-faint italic truncate">"{link.context}"</div>
                        )}
                        <div className="flex items-center gap-2 mt-1">
                          <Badge label={link.handoff_status} variant={statusVariant(link.handoff_status)} />
                          <span className="text-xs text-faint">
                            {new Date(link.created_at).toLocaleTimeString()}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>
      )}
    </div>
  )
}
