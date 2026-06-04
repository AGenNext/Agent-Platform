import { useEffect, useMemo, useState } from 'react'
import { api, type ModelRoute } from '../api'
import { Badge, statusVariant } from '../components/Badge'
import { Card, CardHeader } from '../components/Card'
import { Activity, DollarSign, Gauge, Workflow } from 'lucide-react'

export function AiGatewayView() {
  const [routes, setRoutes] = useState<ModelRoute[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.gatewayRoutes().then(setRoutes).catch(() => setRoutes([])).finally(() => setLoading(false))
  }, [])

  const totals = useMemo(() => routes.reduce((a, r) => ({
    requests: a.requests + r.requests,
    cost: a.cost + r.cost_usd,
    p95: Math.max(a.p95, r.p95_ms),
    err: a.err + r.error_rate * r.requests,
  }), { requests: 0, cost: 0, p95: 0, err: 0 }), [routes])

  const stats = [
    { label: 'Requests', value: totals.requests.toLocaleString(), icon: <Activity size={15} /> },
    { label: 'Spend', value: `$${totals.cost.toFixed(2)}`, icon: <DollarSign size={15} /> },
    { label: 'p95 latency', value: `${totals.p95} ms`, icon: <Gauge size={15} /> },
    { label: 'Error rate', value: `${totals.requests ? ((totals.err / totals.requests) * 100).toFixed(2) : '0'}%`, icon: <Workflow size={15} /> },
  ]

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {stats.map(s => (
          <div key={s.label} className="rounded-xl p-4 border border-line bg-surface/60">
            <div className="flex items-center gap-2 text-faint text-xs mb-1.5"><span className="text-muted">{s.icon}</span>{s.label}</div>
            <div className="text-2xl font-semibold text-ink nums tracking-tight">{s.value}</div>
          </div>
        ))}
      </div>

      <Card>
        <CardHeader title="Model Routes" />
        {loading && <div className="text-faint text-sm animate-pulse">Loading routes…</div>}
        {!loading && (
          <div className="overflow-hidden rounded-lg border border-line">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-surface/60 text-faint text-[11px] uppercase tracking-wide">
                  <th className="text-left font-medium px-4 py-2.5">Provider / Model</th>
                  <th className="text-right font-medium px-4 py-2.5">Requests</th>
                  <th className="text-right font-medium px-4 py-2.5">Cost</th>
                  <th className="text-right font-medium px-4 py-2.5">p95</th>
                  <th className="text-right font-medium px-4 py-2.5">Errors</th>
                  <th className="text-left font-medium px-4 py-2.5 w-40">Traffic</th>
                  <th className="text-right font-medium px-4 py-2.5">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {routes.map(r => (
                  <tr key={r.id} className="hover:bg-raised/40 transition-colors">
                    <td className="px-4 py-3">
                      <div className="font-medium text-ink">{r.model}</div>
                      <div className="text-xs text-faint">{r.provider}</div>
                    </td>
                    <td className="px-4 py-3 text-right text-muted nums">{r.requests.toLocaleString()}</td>
                    <td className="px-4 py-3 text-right text-muted nums">${r.cost_usd.toFixed(2)}</td>
                    <td className="px-4 py-3 text-right text-muted nums">{r.p95_ms} ms</td>
                    <td className={`px-4 py-3 text-right nums ${r.error_rate > 0.02 ? 'text-bad' : 'text-muted'}`}>{(r.error_rate * 100).toFixed(2)}%</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-1.5 rounded-full bg-line overflow-hidden">
                          <div className="h-full rounded-full bg-gradient-to-r from-accent-strong to-accent" style={{ width: `${Math.round(r.share * 100)}%` }} />
                        </div>
                        <span className="text-[11px] text-faint nums w-8 text-right">{Math.round(r.share * 100)}%</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right"><Badge label={r.status} variant={statusVariant(r.status)} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}
