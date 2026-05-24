interface BadgeProps {
  label: string
  variant?: 'green' | 'red' | 'yellow' | 'blue' | 'gray'
}

const colors = {
  green: 'bg-emerald-900/40 text-emerald-400 border-emerald-800',
  red:   'bg-red-900/40 text-red-400 border-red-800',
  yellow:'bg-amber-900/40 text-amber-400 border-amber-800',
  blue:  'bg-indigo-900/40 text-indigo-400 border-indigo-800',
  gray:  'bg-slate-800 text-slate-400 border-slate-700',
}

export function Badge({ label, variant = 'gray' }: BadgeProps) {
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${colors[variant]}`}>
      {label}
    </span>
  )
}

export function statusVariant(status: string): BadgeProps['variant'] {
  if (['ok', 'running', 'connected', 'passed', 'completed'].includes(status)) return 'green'
  if (['error', 'failed', 'unreachable'].includes(status)) return 'red'
  if (['pending', 'draft', 'initiated'].includes(status)) return 'yellow'
  if (['degraded'].includes(status)) return 'yellow'
  return 'blue'
}
