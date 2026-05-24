import { useState } from 'react'
import { Activity, Box, GitBranch, LayoutDashboard, Radio } from 'lucide-react'
import { HealthView } from './views/HealthView'
import { ObjectivesView } from './views/ObjectivesView'
import { ArtifactsView } from './views/ArtifactsView'
import { TraceView } from './views/TraceView'
import { TimelineView } from './views/TimelineView'

type View = 'health' | 'objectives' | 'artifacts' | 'trace' | 'timeline'

const nav: { id: View; label: string; icon: React.ReactNode }[] = [
  { id: 'health',     label: 'Health',      icon: <Activity size={16} /> },
  { id: 'objectives', label: 'Objectives',  icon: <LayoutDashboard size={16} /> },
  { id: 'artifacts',  label: 'Artifacts',   icon: <Box size={16} /> },
  { id: 'trace',      label: 'A2A Trace',   icon: <GitBranch size={16} /> },
  { id: 'timeline',   label: 'Timeline',    icon: <Radio size={16} /> },
]

export default function App() {
  const [view, setView] = useState<View>('health')

  return (
    <div className="flex min-h-screen">
      {/* Sidebar */}
      <aside className="w-52 shrink-0 bg-[#0d1117] border-r border-[#1f2937] flex flex-col">
        <div className="px-4 py-5 border-b border-[#1f2937]">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-indigo-600 flex items-center justify-center">
              <span className="text-white text-xs font-bold">R</span>
            </div>
            <div>
              <div className="text-sm font-semibold text-white">RealGraph</div>
              <div className="text-xs text-slate-500">Agent Platform</div>
            </div>
          </div>
        </div>

        <nav className="flex-1 px-2 py-3 space-y-0.5">
          {nav.map(({ id, label, icon }) => (
            <button
              key={id}
              onClick={() => setView(id)}
              className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-md text-sm transition-colors ${
                view === id
                  ? 'bg-indigo-900/50 text-indigo-300 border border-indigo-800/50'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-[#1a2233]'
              }`}
            >
              {icon}
              {label}
            </button>
          ))}
        </nav>

        <div className="px-4 py-3 border-t border-[#1f2937]">
          <a
            href="/api/docs"
            target="_blank"
            rel="noreferrer"
            className="text-xs text-slate-500 hover:text-indigo-400 transition-colors"
          >
            API Docs →
          </a>
        </div>
      </aside>

      {/* Main */}
      <main className="flex-1 flex flex-col min-w-0">
        <header className="h-12 px-6 flex items-center border-b border-[#1f2937] bg-[#0d1117]/50 backdrop-blur-sm">
          <h1 className="text-sm font-medium text-slate-300">
            {nav.find(n => n.id === view)?.label}
          </h1>
        </header>

        <div className="flex-1 p-6 overflow-auto">
          {view === 'health'     && <HealthView />}
          {view === 'objectives' && <ObjectivesView />}
          {view === 'artifacts'  && <ArtifactsView />}
          {view === 'trace'      && <TraceView />}
          {view === 'timeline'   && <TimelineView />}
        </div>
      </main>
    </div>
  )
}
