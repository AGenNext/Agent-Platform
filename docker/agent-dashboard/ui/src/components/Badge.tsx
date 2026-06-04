interface BadgeProps {
  label: string
  variant?: 'green' | 'red' | 'yellow' | 'blue' | 'gray'
}

const styles: Record<NonNullable<BadgeProps['variant']>, { wrap: string; dot: string }> = {
  green:  { wrap: 'bg-ok/10 text-ok ring-ok/25',          dot: 'bg-ok' },
  red:    { wrap: 'bg-bad/10 text-bad ring-bad/25',        dot: 'bg-bad' },
  yellow: { wrap: 'bg-warn/10 text-warn ring-warn/25',     dot: 'bg-warn' },
  blue:   { wrap: 'bg-accent/10 text-accent ring-accent/25', dot: 'bg-accent' },
  gray:   { wrap: 'bg-muted/10 text-muted ring-line-strong', dot: 'bg-faint' },
}

export function Badge({ label, variant = 'gray' }: BadgeProps) {
  const s = styles[variant]
  return (
    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-medium ring-1 ${s.wrap}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${s.dot}`} />
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
