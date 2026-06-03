import { useState } from 'react'
import { Activity, Bot, Box, Flag, GitBranch, LayoutDashboard, LayoutGrid, MessageSquare, Radio, Search, Wand2 } from 'lucide-react'
import { SpacesView } from './views/SpacesView'
import { ChannelsView } from './views/ChannelsView'
import { AgentsView } from './views/AgentsView'
import { ComposerView } from './views/ComposerView'
import { AiGatewayView } from './views/AiGatewayView'
import { MilestonesView } from './views/MilestonesView'
import { HealthView } from './views/HealthView'
import { ObjectivesView } from './views/ObjectivesView'
import { ArtifactsView } from './views/ArtifactsView'
import { TraceView } from './views/TraceView'

type View = 'spaces' | 'chat' | 'agents' | 'composer' | 'milestones' | 'objectives' | 'artifacts' | 'trace' | 'gateway' | 'health'

type NavItem = { id: View; label: string; icon: React.ReactNode; hint: string }

const sections: { heading: string; items: NavItem[] }[] = [
  {
    heading: 'Build',
    items: [
      { id: 'composer', label: 'Composer', icon: <Wand2 size={17} />,        hint: 'Chat → generated agent pipeline' },
      { id: 'spaces',   label: 'Spaces',   icon: <LayoutGrid size={17} />,   hint: 'Your agent workspaces' },
      { id: 'chat',     label: 'Chat',     icon: <MessageSquare size={17} />, hint: 'Agent, system & human channels' },
      { id: 'agents',   label: 'Agents',   icon: <Bot size={17} />,          hint: 'Agent roster across spaces' },
    ],
  },
  {
    heading: 'Operate',
    items: [
      { id: 'milestones', label: 'Milestones', icon: <Flag size={17} />,            hint: 'Delivery progress & due dates' },
      { id: 'objectives', label: 'Objectives', icon: <LayoutDashboard size={17} />, hint: 'Goals & runs' },
      { id: 'artifacts',  label: 'Artifacts',  icon: <Box size={17} />,             hint: 'Outputs, eval & trust' },
      { id: 'trace',      label: 'A2A Trace',  icon: <GitBranch size={17} />,       hint: 'Agent handoff chains' },
    ],
  },
  {
    heading: 'Platform',
    items: [
      { id: 'gateway', label: 'AI Gateway', icon: <Radio size={17} />,   hint: 'Model routing, cost & latency' },
      { id: 'health',  label: 'Health',     icon: <Activity size={17} />, hint: 'Platform status & usage' },
    ],
  },
]

const allItems = sections.flatMap(s => s.items)

export default function App() {
  const [view, setView] = useState<View>('composer')
  const active = allItems.find(n => n.id === view)!

  return (
    <div className="flex min-h-screen">
      {/* Sidebar */}
      <aside className="w-60 shrink-0 bg-surface/80 backdrop-blur-xl border-r border-line flex flex-col">
        <div className="px-5 py-5">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-accent to-accent-strong flex items-center justify-center shadow-lg shadow-accent-strong/20 ring-1 ring-white/10">
              <span className="text-white text-sm font-bold tracking-tight">R</span>
            </div>
            <div className="leading-tight">
              <div className="text-[15px] font-semibold text-ink tracking-tight">RealGraph</div>
              <div className="text-[11px] text-faint">Agent Workspace</div>
            </div>
          </div>
        </div>

        <div className="px-5">
          <div className="h-px bg-gradient-to-r from-transparent via-line-strong to-transparent" />
        </div>

        <nav className="flex-1 px-3 py-4 space-y-5 overflow-auto">
          {sections.map(section => (
            <div key={section.heading} className="space-y-1">
              <div className="px-3 pb-1 text-[10px] font-semibold uppercase tracking-[0.14em] text-faint">{section.heading}</div>
              {section.items.map(({ id, label, icon }) => {
                const on = view === id
                return (
                  <button
                    key={id}
                    onClick={() => setView(id)}
                    className={`group relative w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-all ${
                      on ? 'bg-raised text-ink shadow-sm ring-1 ring-line-strong' : 'text-muted hover:text-ink hover:bg-raised/60'
                    }`}
                  >
                    <span className={`absolute left-0 top-1/2 -translate-y-1/2 h-5 w-[3px] rounded-full bg-accent transition-opacity ${on ? 'opacity-100' : 'opacity-0'}`} />
                    <span className={on ? 'text-accent' : 'text-faint group-hover:text-muted'}>{icon}</span>
                    {label}
                  </button>
                )
              })}
            </div>
          ))}
        </nav>

        <div className="px-5 py-4 border-t border-line">
          <a href="/api/docs" target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 text-xs text-faint hover:text-accent transition-colors">
            API Reference <span aria-hidden>↗</span>
          </a>
        </div>
      </aside>

      {/* Main */}
      <main className="flex-1 flex flex-col min-w-0">
        <header className="h-16 px-10 flex items-center justify-between border-b border-line bg-surface/40 backdrop-blur-xl sticky top-0 z-10">
          <div>
            <h1 className="text-[15px] font-semibold text-ink tracking-tight">{active.label}</h1>
            <p className="text-xs text-faint mt-0.5">{active.hint}</p>
          </div>
          <div className="flex items-center gap-3 text-xs text-muted">
            <label className="hidden sm:flex items-center gap-2 rounded-lg border border-line bg-field/60 px-3 py-1.5 w-64 focus-within:border-accent transition-colors">
              <Search size={14} className="text-faint" />
              <input
                placeholder="Search spaces, agents, runs…"
                className="bg-transparent text-sm text-ink placeholder:text-faint focus:outline-none w-full"
              />
              <kbd className="text-[10px] text-faint border border-line rounded px-1">⌘K</kbd>
            </label>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-line bg-raised/60 px-2.5 py-1">
              <span className="w-1.5 h-1.5 rounded-full bg-ok shadow-[0_0_8px] shadow-ok/60" />
              Live
            </span>
          </div>
        </header>

        <div className="flex-1 px-10 py-8 overflow-auto">
          <div className={`mx-auto ${view === 'composer' ? 'max-w-none h-full' : 'max-w-6xl'}`}>
            {view === 'spaces'     && <SpacesView />}
            {view === 'chat'       && <ChannelsView />}
            {view === 'agents'     && <AgentsView />}
            {view === 'composer'   && <ComposerView />}
            {view === 'milestones' && <MilestonesView />}
            {view === 'objectives' && <ObjectivesView />}
            {view === 'artifacts'  && <ArtifactsView />}
            {view === 'trace'      && <TraceView />}
            {view === 'gateway'    && <AiGatewayView />}
            {view === 'health'     && <HealthView />}
          </div>
        </div>
      </main>
    </div>
  )
}
