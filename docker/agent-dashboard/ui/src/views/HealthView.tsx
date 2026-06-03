import { useEffect, useState } from 'react'
import { api, type HealthStatus } from '../api'
import { Card, CardHeader } from '../components/Card'
import { Badge, statusVariant } from '../components/Badge'
import { Activity, Database, HardDrive, Server } from 'lucide-react'

export function HealthView() {
  const [health, setHealth] = useState<HealthStatus | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [lastChecked, setLastChecked] = useState<Date | null>(null)

  async function check() {
    try {
      const h = await api.health()
      setHealth(h)
      setError(null)
    } catch (e) {
      setError(String(e))
    }
    setLastChecked(new Date())
  }

  useEffect(() => {
    check()
    const t = setInterval(check, 10_000)
    return () => clearInterval(t)
  }, [])

  const services = health ? [
    { label: 'Agent Knowledge API', value: health.status, icon: <Server size={16} /> },
    { label: 'SurrealDB', value: health.surrealdb, icon: <Database size={16} /> },
    { label: 'Version', value: health.version, icon: <Activity size={16} /> },
    { label: 'Environment', value: health.env, icon: <HardDrive size={16} /> },
  ] : []

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title="Platform Health"
          action={
            <div className="flex items-center gap-3">
              {lastChecked && (
                <span className="text-xs text-faint">
                  Checked {lastChecked.toLocaleTimeString()}
                </span>
              )}
              <button
                onClick={check}
                className="text-xs px-3 py-1 rounded bg-accent-strong hover:bg-accent text-white transition-colors"
              >
                Refresh
              </button>
            </div>
          }
        />

        {error && (
          <div className="p-4 rounded-lg bg-bad/10 border border-bad/30 text-bad text-sm">
            Cannot reach Agent Knowledge API — is the service running?<br />
            <span className="text-xs opacity-70 font-mono">{error}</span>
          </div>
        )}

        {!error && !health && (
          <div className="text-faint text-sm animate-pulse">Checking...</div>
        )}

        {health && (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {services.map(({ label, value, icon }) => (
              <div key={label} className="rounded-xl p-4 border border-line bg-surface/60 hover:border-line-strong transition-colors">
                <div className="flex items-center gap-2 text-faint text-xs mb-3">
                  <span className="text-muted">{icon}</span> {label}
                </div>
                <Badge label={value} variant={statusVariant(value)} />
              </div>
            ))}
          </div>
        )}
      </Card>

      <Card>
        <CardHeader title="Usage Summary" />
        <UsageSummaryPanel />
      </Card>
    </div>
  )
}

function UsageSummaryPanel() {
  const [summary, setSummary] = useState<Awaited<ReturnType<typeof api.usageSummary>> | null>(null)

  useEffect(() => {
    api.usageSummary().then(setSummary).catch(() => setSummary(null))
  }, [])

  if (!summary) return <div className="text-faint text-sm">No usage data yet.</div>

  const stats = [
    { label: 'Total Calls', value: summary.total_calls },
    { label: 'Input Tokens', value: summary.total_input_tokens.toLocaleString() },
    { label: 'Output Tokens', value: summary.total_output_tokens.toLocaleString() },
    { label: 'Total Cost', value: `$${summary.total_cost_usd.toFixed(4)}` },
    { label: 'Avg Cost', value: `$${summary.avg_cost_usd.toFixed(4)}` },
  ]

  return (
    <div className="grid grid-cols-3 gap-3 sm:grid-cols-5">
      {stats.map(({ label, value }) => (
        <div key={label} className="rounded-xl p-4 border border-line bg-surface/60 hover:border-line-strong transition-colors">
          <div className="text-[11px] uppercase tracking-wide text-faint mb-1.5">{label}</div>
          <div className="text-2xl font-semibold text-ink nums tracking-tight">{value}</div>
        </div>
      ))}
    </div>
  )
}
