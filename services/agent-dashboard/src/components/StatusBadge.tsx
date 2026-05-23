type Status = "ok" | "connected" | "disconnected" | "pending" | "running" | "completed" | "failed" | string;

const colors: Record<string, string> = {
  ok: "var(--green)",
  connected: "var(--green)",
  completed: "var(--green)",
  running: "var(--accent)",
  pending: "var(--yellow)",
  disconnected: "var(--red)",
  failed: "var(--red)",
};

export function StatusBadge({ status }: { status: Status }) {
  const color = colors[status] ?? "var(--text-muted)";
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 6,
        fontSize: 12,
        fontWeight: 600,
        textTransform: "uppercase",
        letterSpacing: "0.06em",
        color,
      }}
    >
      <span
        style={{
          width: 7,
          height: 7,
          borderRadius: "50%",
          background: color,
          flexShrink: 0,
        }}
      />
      {status}
    </span>
  );
}
