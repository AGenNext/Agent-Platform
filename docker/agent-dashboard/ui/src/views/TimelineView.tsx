import { useEffect, useRef, useState } from 'react'
import { api, type Objective } from '../api'
import { Card, CardHeader } from '../components/Card'
import { Badge, statusVariant } from '../components/Badge'
import { Activity, Box, Play, Plus, ShieldCheck, Star, Zap } from 'lucide-react'

interface RuntimeEvent {
  id: string
  entity_type: string
  entity_id: string
  event_type: string
  payload: Record<string, unknown>
  occurred_at: string
}

const EVENT_META: Record<string, { icon: React.ReactNode; label: string; color: string }> = {
  created:        { icon: <Plus size={13} />,        label: 'Created',         color: 'text-slate-400' },
  run_triggered:  { icon: <Play size={13} />,         label: 'Run triggered',   color: 'text-indigo-400' },
  status_changed: { icon: <Activity size={13} />,     label: 'Status changed',  color: 'text-amber-400' },
  eval_completed: { icon: <Star size={13} />,         label: 'Eval completed',  color: 'text-amber-400' },
  trust_gate:     { icon: <ShieldCheck size={13} />,  label: 'Trust gate',      color: 'text-indigo-400' },
  artifact_created: { icon: <Box size={13} />,        label: 'Artifact created', color: 'text-emerald-400' },
}

function eventMeta(event_type: string) {
  return EVENT_META[event_type] ?? { icon: <Zap size={13} />, label: event_type, color: 'text-slate-500' }
}

export function TimelineView() {
  const [objectives, setObjectives] = useState<Objective[]>([])
  const [selected, setSelected] = useState<string | null>(null)
  const [events, setEvents] = useState<RuntimeEvent[]>([])
  const [live, setLive] = useState(false)
  const esRef = useRef<EventSource | null>(null)

  useEffect(() => {
    api.listObjectives().then(setObjectives)
  }, [])

  async function loadEvents(objectiveId: string) {
    const res = await fetch(`/api/events/objectives/${objectiveId}`)
    const data = await res.json()
    setEvents(Array.isArray(data) ? data : [])
  }

  function startStream(objectiveId: string) {
    if (esRef.current) esRef.current.close()
    const es = new EventSource(`/api/events/objectives/${objectiveId}/stream`)
    es.onmessage = (e) => {
      try {
        const ev: RuntimeEvent = JSON.parse(e.data)
        setEvents(prev => {
          if (prev.find(p => p.id === ev.id)) return prev
          return [...prev, ev].sort(
            (a, b) => new Date(a.occurred_at).getTime() - new Date(b.occurred_at).getTime()
          )
        })
      } catch { /* ignore */ }
    }
    esRef.current = es
    setLive(true)
  }

  function stopStream() {
    esRef.current?.close()
    esRef.current = null
    setLive(false)
  }

  useEffect(() => () => esRef.current?.close(), [])

  async function select(id: string) {
    stopStream()
    setSelected(id)
    setEvents([])
    await loadEvents(id)
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 h-full">
      {/* Objective picker */}
      <Card className="md:col-span-1 self-start">
        <CardHeader title="Objectives" />
        {objectives.length === 0 && (
          <div className="text-slate-500 text-sm">No objectives yet.</div>
        )}
        <div className="space-y-1">
          {objectives.map(obj => (
            <button
              key={obj.id}
              onClick={() => select(obj.id)}
              className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
                selected === obj.id
                  ? 'bg-indigo-900/40 text-indigo-300 border border-indigo-700'
                  : 'text-slate-300 hover:bg-[#1a2233] border border-transparent'
              }`}
            >
              <div className="font-medium truncate">{obj.title}</div>
              <div className="flex items-center gap-1.5 mt-0.5">
                <Badge label={obj.status} variant={statusVariant(obj.status)} />
                <span className="text-xs text-slate-600">{obj.objective_type}</span>
              </div>
            </button>
          ))}
        </div>
      </Card>

      {/* Timeline */}
      <Card className="md:col-span-2">
        <CardHeader
          title={selected ? 'Event Timeline' : 'Select an objective'}
          action={selected && (
            <div className="flex items-center gap-2">
              {live && (
                <span className="flex items-center gap-1 text-xs text-emerald-400">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                  Live
                </span>
              )}
              <button
                onClick={() => live ? stopStream() : startStream(selected)}
                className={`text-xs px-3 py-1 rounded transition-colors ${
                  live
                    ? 'bg-red-900/40 text-red-400 hover:bg-red-900/60 border border-red-800'
                    : 'bg-emerald-900/40 text-emerald-400 hover:bg-emerald-900/60 border border-emerald-800'
                }`}
              >
                {live ? 'Stop' : 'Go Live'}
              </button>
              <button
                onClick={() => selected && loadEvents(selected)}
                className="text-xs px-3 py-1 rounded bg-[#1a2233] text-slate-400 hover:text-slate-200 border border-[#2d3748] transition-colors"
              >
                Refresh
              </button>
            </div>
          )}
        />

        {!selected && (
          <div className="text-center py-12 text-slate-500 text-sm">
            Select an objective on the left to see its event trail.
          </div>
        )}

        {selected && events.length === 0 && (
          <div className="text-center py-12 text-slate-500 text-sm">
            No events recorded yet. Run the objective to see activity.
          </div>
        )}

        {events.length > 0 && (
          <div className="relative">
            <div className="absolute left-[18px] top-0 bottom-0 w-px bg-[#1f2937]" />
            <div className="space-y-3">
              {events.map((ev, i) => {
                const meta = eventMeta(ev.event_type)
                const isLast = i === events.length - 1
                return (
                  <div key={ev.id} className="flex gap-3 relative">
                    <div className={`shrink-0 w-9 h-9 rounded-full border flex items-center justify-center z-10 ${
                      isLast
                        ? 'bg-indigo-900/60 border-indigo-600'
                        : 'bg-[#111827] border-[#1f2937]'
                    } ${meta.color}`}>
                      {meta.icon}
                    </div>
                    <div className="flex-1 min-w-0 pt-1 pb-2">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-medium text-slate-200">{meta.label}</span>
                        <span className="text-xs text-slate-600 font-mono">{ev.entity_type}</span>
                        {ev.entity_id && (
                          <span className="text-xs text-slate-700 font-mono truncate max-w-28">
                            {ev.entity_id.replace(/^\w+:/, '')}
                          </span>
                        )}
                      </div>
                      <EventPayload payload={ev.payload} eventType={ev.event_type} />
                      <div className="text-xs text-slate-600 mt-1">
                        {new Date(ev.occurred_at).toLocaleTimeString()} · {new Date(ev.occurred_at).toLocaleDateString()}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        )}
      </Card>
    </div>
  )
}

function EventPayload({ payload, eventType }: { payload: Record<string, unknown>; eventType: string }) {
  if (eventType === 'status_changed') {
    return (
      <div className="flex items-center gap-2">
        <Badge label={String(payload.from ?? '?')} variant={statusVariant(String(payload.from ?? ''))} />
        <span className="text-slate-600">→</span>
        <Badge label={String(payload.to ?? '?')} variant={statusVariant(String(payload.to ?? ''))} />
      </div>
    )
  }
  if (eventType === 'eval_completed') {
    const score = Number(payload.composite_score ?? 0)
    const passed = Boolean(payload.passed)
    return (
      <div className="flex items-center gap-2">
        <Badge label={passed ? 'passed' : 'failed'} variant={passed ? 'green' : 'red'} />
        <span className="text-xs text-slate-400">{(score * 100).toFixed(0)}% composite</span>
      </div>
    )
  }
  if (eventType === 'trust_gate') {
    const score = Number(payload.score ?? 0)
    const passed = Boolean(payload.passed)
    return (
      <div className="flex items-center gap-2">
        <Badge label={passed ? 'passed' : 'failed'} variant={passed ? 'green' : 'red'} />
        <span className="text-xs text-slate-400">{(score * 100).toFixed(0)}% trust</span>
      </div>
    )
  }
  if (eventType === 'created' && payload.title) {
    return <div className="text-xs text-slate-400 truncate">"{String(payload.title)}"</div>
  }
  const entries = Object.entries(payload).filter(([, v]) => v !== null && v !== undefined)
  if (!entries.length) return null
  return (
    <div className="flex flex-wrap gap-x-3 gap-y-0.5">
      {entries.map(([k, v]) => (
        <span key={k} className="text-xs text-slate-500">
          <span className="text-slate-600">{k}:</span> {String(v)}
        </span>
      ))}
    </div>
  )
}
