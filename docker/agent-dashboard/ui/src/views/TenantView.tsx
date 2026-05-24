import { useEffect, useState } from 'react'
import { api, type Tenant, type TenantUser, type ApiKey, type BillingSubscription, type AuditLog } from '../api'
import Card from '../components/Card'

type Tab = 'users' | 'keys' | 'billing' | 'audit'

const PLAN_COLORS: Record<string, string> = {
  free:       'bg-slate-700 text-slate-300',
  pro:        'bg-indigo-900/60 text-indigo-300',
  enterprise: 'bg-amber-900/60 text-amber-300',
}

const ROLE_COLORS: Record<string, string> = {
  owner:  'text-amber-400',
  admin:  'text-indigo-400',
  editor: 'text-emerald-400',
  viewer: 'text-slate-400',
}

const RESULT_COLORS: Record<string, string> = {
  success: 'text-emerald-400',
  failure: 'text-red-400',
  denied:  'text-amber-400',
}

export function TenantView() {
  const [tenants, setTenants] = useState<Tenant[]>([])
  const [selected, setSelected] = useState<Tenant | null>(null)
  const [tab, setTab] = useState<Tab>('users')

  // Create tenant form
  const [newName, setNewName] = useState('')
  const [newPlan, setNewPlan] = useState('free')
  const [creating, setCreating] = useState(false)

  useEffect(() => { loadTenants() }, [])

  async function loadTenants() {
    try {
      const t = await api.listTenants()
      setTenants(t)
      if (t.length > 0 && !selected) setSelected(t[0])
    } catch {}
  }

  async function handleCreate() {
    if (!newName.trim()) return
    setCreating(true)
    try {
      const t = await api.createTenant({ name: newName, plan: newPlan })
      setNewName('')
      await loadTenants()
      setSelected(t)
    } catch {}
    setCreating(false)
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-[220px_1fr] gap-6">
        {/* Tenant list */}
        <div className="space-y-3">
          <Card title="Tenants">
            {tenants.length === 0
              ? <p className="text-xs text-slate-500">No tenants yet.</p>
              : tenants.map(t => (
                <button
                  key={t.id}
                  onClick={() => { setSelected(t); setTab('users') }}
                  className={`w-full text-left px-3 py-2 rounded border text-xs mb-1 transition-colors ${
                    selected?.id === t.id
                      ? 'border-indigo-600 bg-indigo-900/30 text-white'
                      : 'border-[#1f2937] text-slate-400 hover:border-slate-600 hover:text-slate-200'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium truncate">{t.name}</span>
                    <span className={`px-1.5 py-0.5 rounded text-[10px] ${PLAN_COLORS[t.plan] ?? PLAN_COLORS.free}`}>{t.plan}</span>
                  </div>
                  <div className="text-slate-600 mt-0.5">{t.slug}</div>
                </button>
              ))
            }
          </Card>

          <Card title="New Tenant">
            <div className="space-y-2">
              <input
                className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
                placeholder="Tenant name"
                value={newName}
                onChange={e => setNewName(e.target.value)}
              />
              <select
                className="w-full bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white focus:outline-none focus:border-indigo-600"
                value={newPlan}
                onChange={e => setNewPlan(e.target.value)}
              >
                {['free', 'pro', 'enterprise'].map(p => <option key={p} value={p}>{p}</option>)}
              </select>
              <button
                onClick={handleCreate}
                disabled={creating || !newName.trim()}
                className="w-full px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded transition-colors"
              >
                {creating ? 'Creating…' : 'Create'}
              </button>
            </div>
          </Card>
        </div>

        {/* Tenant detail */}
        {selected ? (
          <div className="space-y-4">
            <div className="flex items-center gap-4 pb-2 border-b border-[#1f2937]">
              <div>
                <h2 className="text-base font-semibold text-white">{selected.name}</h2>
                <p className="text-xs text-slate-500">{selected.id}</p>
              </div>
              <span className={`px-2 py-0.5 rounded text-xs ${PLAN_COLORS[selected.plan] ?? PLAN_COLORS.free}`}>{selected.plan}</span>
              <span className={`text-xs ${selected.status === 'active' ? 'text-emerald-400' : 'text-red-400'}`}>{selected.status}</span>
            </div>

            {/* Tabs */}
            <div className="flex gap-1">
              {(['users', 'keys', 'billing', 'audit'] as Tab[]).map(t => (
                <button
                  key={t}
                  onClick={() => setTab(t)}
                  className={`px-3 py-1.5 text-xs rounded transition-colors ${
                    tab === t ? 'bg-indigo-800 text-indigo-200' : 'text-slate-500 hover:text-slate-300'
                  }`}
                >
                  {t === 'keys' ? 'API Keys' : t.charAt(0).toUpperCase() + t.slice(1)}
                </button>
              ))}
            </div>

            {tab === 'users'   && <UsersTab tenantId={selected.id} />}
            {tab === 'keys'    && <ApiKeysTab tenantId={selected.id} />}
            {tab === 'billing' && <BillingTab tenantId={selected.id} />}
            {tab === 'audit'   && <AuditTab tenantId={selected.id} />}
          </div>
        ) : (
          <div className="flex items-center justify-center h-40 text-slate-600 text-sm">
            Select or create a tenant
          </div>
        )}
      </div>
    </div>
  )
}

// ── Users tab ─────────────────────────────────────────────────────────────────

function UsersTab({ tenantId }: { tenantId: string }) {
  const [users, setUsers] = useState<TenantUser[]>([])
  const [email, setEmail] = useState('')
  const [role, setRole] = useState('viewer')
  const [adding, setAdding] = useState(false)

  useEffect(() => { api.listUsers(tenantId).then(setUsers).catch(() => {}) }, [tenantId])

  async function handleAdd() {
    if (!email.trim()) return
    setAdding(true)
    try {
      await api.createUser(tenantId, { email, role })
      setEmail('')
      const updated = await api.listUsers(tenantId)
      setUsers(updated)
    } catch {}
    setAdding(false)
  }

  return (
    <Card title={`Users (${users.length})`}>
      <div className="space-y-4">
        <table className="w-full text-xs">
          <thead>
            <tr className="text-slate-500 border-b border-[#1f2937]">
              <th className="text-left py-1.5 font-normal">Email</th>
              <th className="text-left py-1.5 font-normal">Name</th>
              <th className="text-left py-1.5 font-normal">Role</th>
              <th className="text-left py-1.5 font-normal">Status</th>
            </tr>
          </thead>
          <tbody>
            {users.map(u => (
              <tr key={u.id} className="border-b border-[#1f2937]/50">
                <td className="py-2 text-slate-300">{u.email}</td>
                <td className="py-2 text-slate-400">{u.display_name}</td>
                <td className={`py-2 font-medium ${ROLE_COLORS[u.role] ?? 'text-slate-400'}`}>{u.role}</td>
                <td className="py-2 text-slate-500">{u.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="flex gap-2 pt-1">
          <input
            className="flex-1 bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
            placeholder="email@example.com"
            value={email}
            onChange={e => setEmail(e.target.value)}
          />
          <select
            className="bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white focus:outline-none"
            value={role}
            onChange={e => setRole(e.target.value)}
          >
            {['viewer', 'editor', 'admin', 'owner'].map(r => <option key={r} value={r}>{r}</option>)}
          </select>
          <button
            onClick={handleAdd}
            disabled={adding || !email.trim()}
            className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
          >
            Invite
          </button>
        </div>
      </div>
    </Card>
  )
}

// ── API Keys tab ──────────────────────────────────────────────────────────────

function ApiKeysTab({ tenantId }: { tenantId: string }) {
  const [keys, setKeys] = useState<ApiKey[]>([])
  const [newKey, setNewKey] = useState('')
  const [newKeyName, setNewKeyName] = useState('')
  const [rawKey, setRawKey] = useState<string | null>(null)
  const [creating, setCreating] = useState(false)

  useEffect(() => { api.listApiKeys(tenantId).then(setKeys).catch(() => {}) }, [tenantId])

  async function handleCreate() {
    if (!newKeyName.trim()) return
    setCreating(true)
    try {
      const result = await api.createApiKey(tenantId, { name: newKeyName })
      setRawKey((result as ApiKey & { raw_key?: string }).raw_key ?? null)
      setNewKeyName('')
      const updated = await api.listApiKeys(tenantId)
      setKeys(updated)
    } catch {}
    setCreating(false)
  }

  async function handleRevoke(keyId: string) {
    await api.revokeApiKey(tenantId, keyId)
    const updated = await api.listApiKeys(tenantId)
    setKeys(updated)
  }

  return (
    <Card title={`API Keys (${keys.length})`}>
      <div className="space-y-4">
        {rawKey && (
          <div className="p-3 bg-emerald-900/20 border border-emerald-700/40 rounded">
            <p className="text-xs text-emerald-400 mb-1 font-medium">Key created — copy it now, it won't be shown again</p>
            <code className="text-xs text-emerald-300 break-all">{rawKey}</code>
            <button onClick={() => setRawKey(null)} className="block mt-2 text-[10px] text-slate-500 hover:text-slate-300">Dismiss</button>
          </div>
        )}

        <table className="w-full text-xs">
          <thead>
            <tr className="text-slate-500 border-b border-[#1f2937]">
              <th className="text-left py-1.5 font-normal">Name</th>
              <th className="text-left py-1.5 font-normal">Prefix</th>
              <th className="text-left py-1.5 font-normal">Scopes</th>
              <th className="text-left py-1.5 font-normal">Status</th>
              <th className="text-left py-1.5 font-normal"></th>
            </tr>
          </thead>
          <tbody>
            {keys.map(k => (
              <tr key={k.id} className="border-b border-[#1f2937]/50">
                <td className="py-2 text-slate-300">{k.name}</td>
                <td className="py-2 font-mono text-slate-400">{k.key_prefix}…</td>
                <td className="py-2 text-slate-500">{(k.scopes ?? []).join(', ')}</td>
                <td className={`py-2 ${k.status === 'active' ? 'text-emerald-400' : 'text-red-400'}`}>{k.status}</td>
                <td className="py-2">
                  {k.status === 'active' && (
                    <button onClick={() => handleRevoke(k.id)} className="text-[10px] text-red-500 hover:text-red-400">revoke</button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="flex gap-2 pt-1">
          <input
            className="flex-1 bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
            placeholder="Key name"
            value={newKeyName}
            onChange={e => setNewKeyName(e.target.value)}
          />
          <button
            onClick={handleCreate}
            disabled={creating || !newKeyName.trim()}
            className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
          >
            {creating ? 'Creating…' : 'Generate'}
          </button>
        </div>
      </div>
    </Card>
  )
}

// ── Billing tab ───────────────────────────────────────────────────────────────

function BillingTab({ tenantId }: { tenantId: string }) {
  const [sub, setSub] = useState<BillingSubscription | null>(null)
  const [targetPlan, setTargetPlan] = useState('pro')
  const [changing, setChanging] = useState(false)

  useEffect(() => { api.getBilling(tenantId).then(setSub).catch(() => {}) }, [tenantId])

  async function handleChangePlan() {
    setChanging(true)
    try {
      const updated = await api.changePlan(tenantId, targetPlan)
      setSub(updated)
    } catch {}
    setChanging(false)
  }

  if (!sub) return <p className="text-xs text-slate-500">No billing data.</p>

  const limits = (sub as BillingSubscription & { limits?: Record<string, number> }).limits ?? {}

  return (
    <div className="space-y-4">
      <Card title="Current Subscription">
        <div className="space-y-3">
          <div className="flex gap-8 text-xs">
            <div><span className="text-slate-500">Plan </span><span className={`font-medium ${PLAN_COLORS[sub.plan_id] ?? ''} px-1.5 py-0.5 rounded`}>{sub.plan_id}</span></div>
            <div><span className="text-slate-500">Status </span><span className={sub.status === 'active' ? 'text-emerald-400' : 'text-red-400'}>{sub.status}</span></div>
            <div><span className="text-slate-500">Since </span><span className="text-slate-300">{sub.current_period_start?.slice(0, 10)}</span></div>
          </div>
          {Object.keys(limits).length > 0 && (
            <div className="grid grid-cols-2 gap-2">
              {Object.entries(limits).map(([k, v]) => (
                <div key={k} className="bg-[#0d1117] rounded p-2">
                  <div className="text-[10px] text-slate-500">{k.replace(/_/g, ' ')}</div>
                  <div className="text-sm font-medium text-white">{v === 0 ? '∞' : v}</div>
                </div>
              ))}
            </div>
          )}
        </div>
      </Card>
      <Card title="Change Plan">
        <div className="flex gap-2">
          <select
            className="bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white focus:outline-none"
            value={targetPlan}
            onChange={e => setTargetPlan(e.target.value)}
          >
            {['free', 'pro', 'enterprise'].map(p => <option key={p} value={p}>{p}</option>)}
          </select>
          <button
            onClick={handleChangePlan}
            disabled={changing || targetPlan === sub.plan_id}
            className="px-3 py-1.5 bg-indigo-700 hover:bg-indigo-600 disabled:opacity-40 text-white text-xs rounded"
          >
            {changing ? 'Updating…' : 'Change Plan'}
          </button>
        </div>
      </Card>
    </div>
  )
}

// ── Audit tab ─────────────────────────────────────────────────────────────────

function AuditTab({ tenantId }: { tenantId: string }) {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [filter, setFilter] = useState('')

  useEffect(() => { loadLogs() }, [tenantId])

  async function loadLogs() {
    try { setLogs(await api.listAuditLogs(tenantId, filter || undefined)) } catch {}
  }

  return (
    <Card title="Audit Log">
      <div className="space-y-3">
        <div className="flex gap-2">
          <input
            className="flex-1 bg-[#0d1117] border border-[#1f2937] rounded px-2 py-1.5 text-xs text-white placeholder-slate-600 focus:outline-none focus:border-indigo-600"
            placeholder="Filter by action (e.g. artifact)"
            value={filter}
            onChange={e => setFilter(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && loadLogs()}
          />
          <button onClick={loadLogs} className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 text-white text-xs rounded">Search</button>
        </div>
        <div className="space-y-1 max-h-96 overflow-y-auto">
          {logs.length === 0
            ? <p className="text-xs text-slate-500">No audit logs.</p>
            : logs.map(log => (
              <div key={log.id} className="flex items-start gap-3 py-1.5 border-b border-[#1f2937]/40 text-xs">
                <span className="text-slate-600 shrink-0 w-36">{log.occurred_at?.slice(0, 19).replace('T', ' ')}</span>
                <span className={`shrink-0 w-14 ${RESULT_COLORS[log.result] ?? 'text-slate-400'}`}>{log.result}</span>
                <span className="text-slate-300 font-medium shrink-0">{log.action}</span>
                {log.resource_type && <span className="text-slate-500">{log.resource_type}:{log.resource_id?.slice(-8)}</span>}
                <span className="text-slate-600 ml-auto shrink-0">{log.actor_type}:{log.actor_id?.slice(-8) ?? 'system'}</span>
              </div>
            ))
          }
        </div>
      </div>
    </Card>
  )
}
