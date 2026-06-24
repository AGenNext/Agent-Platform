import { Boxes, Bot, Database, KeyRound, Server, ShieldCheck } from 'lucide-react';

const stats = [
  { label: 'Workspaces', value: '3', icon: Boxes },
  { label: 'Agents', value: '12', icon: Bot },
  { label: 'Deployments', value: '9', icon: Server },
  { label: 'Secrets', value: '6', icon: KeyRound },
];

const actions = [
  'Create Workspace',
  'Deploy Agent',
  'View Logs',
  'Add Secret',
  'Restart Deployment',
  'Check Policy',
];

export default function Page() {
  return (
    <main className="min-h-screen bg-slate-950 text-slate-100">
      <aside className="fixed inset-y-0 left-0 w-64 border-r border-slate-800 bg-slate-950 p-6">
        <div className="text-xl font-semibold">AGenNext Console</div>
        <div className="mt-1 text-sm text-slate-400">Internal control panel</div>
        <nav className="mt-10 space-y-2 text-sm">
          {['Dashboard', 'Workspaces', 'Agents', 'Deployments', 'Logs', 'Secrets', 'Settings'].map((item) => (
            <a key={item} className="block rounded-lg px-3 py-2 text-slate-300 hover:bg-slate-900 hover:text-white" href="#">
              {item}
            </a>
          ))}
        </nav>
      </aside>

      <section className="ml-64 p-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Internal Agent Console</h1>
            <p className="mt-2 text-slate-400">hPanel-style operations for workspaces, agents, secrets, and deployments.</p>
          </div>
          <button className="rounded-lg bg-white px-4 py-2 text-sm font-medium text-slate-950">Create Agent</button>
        </div>

        <div className="mt-8 grid grid-cols-4 gap-4">
          {stats.map((stat) => {
            const Icon = stat.icon;
            return (
              <div key={stat.label} className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
                <div className="flex items-center justify-between text-slate-400">
                  <span className="text-sm">{stat.label}</span>
                  <Icon className="h-5 w-5" />
                </div>
                <div className="mt-4 text-3xl font-semibold">{stat.value}</div>
              </div>
            );
          })}
        </div>

        <div className="mt-8 grid grid-cols-3 gap-6">
          <div className="col-span-2 rounded-2xl border border-slate-800 bg-slate-900 p-6">
            <h2 className="text-lg font-semibold">Quick Actions</h2>
            <div className="mt-5 grid grid-cols-3 gap-3">
              {actions.map((action) => (
                <button key={action} className="rounded-xl border border-slate-800 bg-slate-950 p-4 text-left text-sm hover:border-slate-600">
                  {action}
                </button>
              ))}
            </div>
          </div>

          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6">
            <div className="flex items-center gap-2">
              <ShieldCheck className="h-5 w-5" />
              <h2 className="text-lg font-semibold">Status</h2>
            </div>
            <div className="mt-5 space-y-4 text-sm">
              <div className="flex justify-between"><span className="text-slate-400">Cluster</span><span>Connected</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Policy</span><span>Local only</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Ingress</span><span>Disabled</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Audit</span><span>Pending</span></div>
            </div>
          </div>
        </div>

        <div className="mt-8 rounded-2xl border border-slate-800 bg-slate-900 p-6">
          <h2 className="text-lg font-semibold">Target Runtime</h2>
          <pre className="mt-4 overflow-auto rounded-xl bg-slate-950 p-4 text-sm text-slate-300">{`Console API → Kubernetes API → k3s → Agent workloads`}</pre>
        </div>
      </section>
    </main>
  );
}
