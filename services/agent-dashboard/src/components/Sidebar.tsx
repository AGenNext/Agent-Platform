import { NavLink } from "react-router-dom";

const links = [
  { to: "/", label: "Get Started" },
  { to: "/health", label: "Platform Health" },
  { to: "/build", label: "Agent Builder" },
  { to: "/agents", label: "Agents" },
  { to: "/deployments", label: "Deployments" },
  { to: "/sessions", label: "Sessions" },
  { to: "/memory", label: "Memory" },
  { to: "/knowledge", label: "Knowledge Base" },
  { to: "/runs", label: "Workflow Runs" },
  { to: "/artifacts", label: "Artifacts" },
  { to: "/traces", label: "Trace Logs" },
  { to: "/billing", label: "Billing" },
  { to: "/integrations", label: "Integrations" },
  { to: "/objectives", label: "Objectives" },
  { to: "/observability", label: "Observability" },
  { to: "/runtime", label: "Runtime" },
];

const navStyle = (active: boolean): React.CSSProperties => ({
  display: "block",
  padding: "8px 12px",
  borderRadius: 6,
  color: active ? "var(--text)" : "var(--text-muted)",
  background: active ? "var(--surface-2)" : "transparent",
  fontWeight: active ? 600 : 400,
  fontSize: 14,
  transition: "color 0.15s, background 0.15s",
});

export function Sidebar() {
  return (
    <aside
      style={{
        width: 220,
        minHeight: "100vh",
        background: "var(--surface)",
        borderRight: "1px solid var(--border)",
        padding: "24px 12px",
        display: "flex",
        flexDirection: "column",
        gap: 4,
        flexShrink: 0,
      }}
    >
      <div
        style={{
          padding: "0 12px 20px",
          borderBottom: "1px solid var(--border)",
          marginBottom: 8,
        }}
      >
        <div style={{ fontSize: 15, fontWeight: 700, color: "var(--text)" }}>
          Agent Platform
        </div>
        <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
          v0.1.0 · local
        </div>
      </div>

      {links.map((link) => (
        <NavLink key={link.to} to={link.to} end={link.to === "/"}>
          {({ isActive }) => (
            <span style={navStyle(isActive)}>{link.label}</span>
          )}
        </NavLink>
      ))}
    </aside>
  );
}
