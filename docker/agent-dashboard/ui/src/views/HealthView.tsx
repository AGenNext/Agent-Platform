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
                <span className="text-xs text-slate-500">
                  Checked {lastChecked.toLocaleTimeString()}
                </span>
              )}
              <button
                onClick={check}
                className="text-xs px-3 py-1 rounded bg-indigo-600 hover:bg-indigo-500 text-white transition-colors"
              >
                Refresh
              </button>
            </div>
          }
        />

        {error && (
          <div className="p-3 rounded bg-red-900/20 border border-red-800 text-red-400 text-sm">
            Cannot reach Agent Knowledge API — is the service running?<br />
            <span className="text-xs opacity-70">{error}</span>
          </div>
        )}

        {!error && !health && (
          <div className="text-slate-500 text-sm animate-pulse">Checking...</div>
        )}

        {health && (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {services.map(({ label, value, icon }) => (
              <div key={label} className="bg-[#0d1117] rounded-lg p-3 border border-[#1f2937]">
                <div className="flex items-center gap-1.5 text-slate-500 text-xs mb-2">
                  {icon} {label}
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

  if (!summary) return <div className="text-slate-500 text-sm">No usage data yet.</div>

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
        <div key={label} className="bg-[#0d1117] rounded-lg p-3 border border-[#1f2937]">
          <div className="text-xs text-slate-500 mb-1">{label}</div>
          <div className="text-lg font-semibold text-indigo-300">{value}</div>
        </div>
      ))}
    </div>
  )
}
