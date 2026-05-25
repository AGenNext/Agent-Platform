import { useEffect, useState } from "react";

const BASE = "/api";

interface OpenApiPath {
  path: string;
  method: string;
  summary?: string;
  description?: string;
  tags?: string[];
  parameters?: { name: string; in: string; required?: boolean; description?: string; schema?: { type?: string } }[];
  requestBody?: { content?: { "application/json"?: { schema?: Record<string, unknown> } } };
  responses?: Record<string, { description?: string }>;
}

const METHOD_COLORS: Record<string, { bg: string; text: string }> = {
  get:    { bg: "#1d4ed822", text: "#3b82f6" },
  post:   { bg: "#15803d22", text: "#22c55e" },
  patch:  { bg: "#b4530022", text: "#f97316" },
  put:    { bg: "#7c3aed22", text: "#a78bfa" },
  delete: { bg: "#b91c1c22", text: "#ef4444" },
};

export function ApiReferencePage() {
  const [spec, setSpec] = useState<Record<string, unknown> | null>(null);
  const [paths, setPaths] = useState<OpenApiPath[]>([]);
  const [tags, setTags] = useState<string[]>([]);
  const [activeTag, setActiveTag] = useState<string>("all");
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch(`${BASE}/openapi.json`)
      .then((r) => {
        if (!r.ok) throw new Error(`${r.status}`);
        return r.json();
      })
      .then((data) => {
        setSpec(data);
        const rawPaths = data.paths as Record<string, Record<string, unknown>> ?? {};
        const parsed: OpenApiPath[] = [];
        const tagSet = new Set<string>();

        for (const [path, methods] of Object.entries(rawPaths)) {
          for (const [method, op] of Object.entries(methods)) {
            if (!["get","post","patch","put","delete"].includes(method)) continue;
            const operation = op as Record<string, unknown>;
            const opTags = (operation.tags as string[]) ?? ["other"];
            opTags.forEach((t) => tagSet.add(t));
            parsed.push({
              path,
              method,
              summary: operation.summary as string | undefined,
              description: operation.description as string | undefined,
              tags: opTags,
              parameters: operation.parameters as OpenApiPath["parameters"],
              requestBody: operation.requestBody as OpenApiPath["requestBody"],
              responses: operation.responses as OpenApiPath["responses"],
            });
          }
        }

        parsed.sort((a, b) => {
          const tagA = a.tags?.[0] ?? "";
          const tagB = b.tags?.[0] ?? "";
          return tagA.localeCompare(tagB) || a.path.localeCompare(b.path);
        });

        setPaths(parsed);
        setTags(["all", ...Array.from(tagSet).sort()]);
        setLoading(false);
      })
      .catch((e) => {
        setError(String(e));
        setLoading(false);
      });
  }, []);

  const toggle = (key: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const filtered = paths.filter((p) => {
    const matchTag = activeTag === "all" || p.tags?.includes(activeTag);
    const matchSearch = !search ||
      p.path.toLowerCase().includes(search.toLowerCase()) ||
      p.summary?.toLowerCase().includes(search.toLowerCase()) ||
      p.method.toLowerCase().includes(search.toLowerCase());
    return matchTag && matchSearch;
  });

  // Group by tag for display
  const grouped: Record<string, OpenApiPath[]> = {};
  for (const p of filtered) {
    const tag = p.tags?.[0] ?? "other";
    (grouped[tag] ??= []).push(p);
  }

  const info = spec?.info as Record<string, unknown> | undefined;

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 12 }}>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700 }}>API Reference</h1>
          {info && (
            <span style={{
              fontSize: 11, padding: "2px 8px", borderRadius: 10,
              background: "var(--accent)22", color: "var(--accent)", fontWeight: 600,
            }}>
              v{info.version as string}
            </span>
          )}
        </div>
        {info?.description && (
          <p style={{ margin: "6px 0 0", color: "var(--text-muted)", fontSize: 13, maxWidth: 600 }}>
            {info.description as string}
          </p>
        )}
      </div>

      {/* Controls */}
      <div style={{ display: "flex", gap: 8, marginBottom: 16, flexWrap: "wrap" }}>
        <input
          placeholder="Search endpoints…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            padding: "7px 12px", borderRadius: 6, border: "1px solid var(--border)",
            background: "var(--surface-2)", color: "var(--text)", fontSize: 13, width: 220,
          }}
        />
        <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
          {tags.map((tag) => (
            <button
              key={tag}
              onClick={() => setActiveTag(tag)}
              style={{
                padding: "5px 10px", borderRadius: 6, fontSize: 12, cursor: "pointer",
                border: activeTag === tag ? "none" : "1px solid var(--border)",
                background: activeTag === tag ? "var(--accent)" : "var(--surface-2)",
                color: activeTag === tag ? "#fff" : "var(--text)",
                fontWeight: activeTag === tag ? 600 : 400,
              }}
            >
              {tag}
            </button>
          ))}
        </div>
        {spec && (
          <a
            href={`${BASE}/docs`}
            target="_blank"
            rel="noreferrer"
            style={{
              marginLeft: "auto", padding: "5px 12px", borderRadius: 6, fontSize: 12,
              border: "1px solid var(--border)", background: "var(--surface-2)",
              color: "var(--text)", textDecoration: "none",
            }}
          >
            Swagger UI ↗
          </a>
        )}
      </div>

      {loading && (
        <div style={{ color: "var(--text-muted)", fontSize: 13, padding: "20px 0" }}>Loading spec…</div>
      )}
      {error && (
        <div style={{
          background: "var(--error)11", border: "1px solid var(--error)44", borderRadius: 8,
          padding: "12px 16px", color: "var(--error)", fontSize: 13,
        }}>
          Could not load OpenAPI spec: {error}
          <br />
          <span style={{ color: "var(--text-muted)", fontSize: 11 }}>
            Make sure the platform API is running at {BASE}
          </span>
        </div>
      )}

      {/* Endpoint groups */}
      {Object.entries(grouped).map(([tag, endpoints]) => (
        <div key={tag} style={{ marginBottom: 20 }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: "var(--text-muted)",
            textTransform: "uppercase", letterSpacing: "0.08em",
            paddingBottom: 8, borderBottom: "1px solid var(--border)", marginBottom: 8,
          }}>
            {tag} <span style={{ fontWeight: 400, opacity: 0.6 }}>({endpoints.length})</span>
          </div>

          {endpoints.map((ep) => {
            const key = `${ep.method}:${ep.path}`;
            const isOpen = expanded.has(key);
            const mc = METHOD_COLORS[ep.method] ?? { bg: "var(--surface-2)", text: "var(--text-muted)" };

            return (
              <div key={key} style={{
                border: "1px solid var(--border)", borderRadius: 8,
                marginBottom: 6, overflow: "hidden",
              }}>
                {/* Row */}
                <div
                  onClick={() => toggle(key)}
                  style={{
                    display: "flex", alignItems: "center", gap: 12,
                    padding: "10px 14px", cursor: "pointer",
                    background: isOpen ? "var(--surface-2)" : "var(--surface)",
                  }}
                >
                  <span style={{
                    fontSize: 10, fontWeight: 800, padding: "2px 7px", borderRadius: 4,
                    background: mc.bg, color: mc.text, textTransform: "uppercase",
                    letterSpacing: "0.05em", minWidth: 46, textAlign: "center", flexShrink: 0,
                  }}>
                    {ep.method}
                  </span>
                  <code style={{ fontSize: 13, fontFamily: "monospace", color: "var(--text)", flex: 1 }}>
                    {ep.path}
                  </code>
                  {ep.summary && (
                    <span style={{ fontSize: 12, color: "var(--text-muted)", marginLeft: "auto" }}>
                      {ep.summary}
                    </span>
                  )}
                  <span style={{ color: "var(--text-muted)", fontSize: 11, marginLeft: 8 }}>
                    {isOpen ? "▲" : "▼"}
                  </span>
                </div>

                {/* Detail */}
                {isOpen && (
                  <div style={{ padding: "14px 16px", borderTop: "1px solid var(--border)", fontSize: 13 }}>
                    {ep.description && (
                      <p style={{ margin: "0 0 12px", color: "var(--text-muted)", fontSize: 12 }}>
                        {ep.description}
                      </p>
                    )}

                    {ep.parameters && ep.parameters.length > 0 && (
                      <div style={{ marginBottom: 12 }}>
                        <div style={{ fontWeight: 600, marginBottom: 6, fontSize: 12 }}>Parameters</div>
                        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
                          <thead>
                            <tr style={{ color: "var(--text-muted)" }}>
                              {["Name", "In", "Type", "Required", "Description"].map((h) => (
                                <th key={h} style={{ padding: "3px 8px", textAlign: "left", fontWeight: 500 }}>{h}</th>
                              ))}
                            </tr>
                          </thead>
                          <tbody>
                            {ep.parameters.map((p) => (
                              <tr key={p.name} style={{ borderTop: "1px solid var(--border)" }}>
                                <td style={{ padding: "5px 8px", fontFamily: "monospace", color: "var(--accent)" }}>{p.name}</td>
                                <td style={{ padding: "5px 8px", color: "var(--text-muted)" }}>{p.in}</td>
                                <td style={{ padding: "5px 8px", color: "var(--text-muted)" }}>{p.schema?.type ?? "—"}</td>
                                <td style={{ padding: "5px 8px" }}>
                                  {p.required ? <span style={{ color: "var(--error)" }}>yes</span> : "no"}
                                </td>
                                <td style={{ padding: "5px 8px", color: "var(--text-muted)" }}>{p.description ?? "—"}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )}

                    {ep.requestBody && (
                      <div style={{ marginBottom: 12 }}>
                        <div style={{ fontWeight: 600, marginBottom: 4, fontSize: 12 }}>Request body</div>
                        <pre style={{
                          background: "var(--surface-2)", borderRadius: 6, padding: "8px 10px",
                          fontSize: 11, overflow: "auto", margin: 0,
                        }}>
                          {JSON.stringify(
                            ep.requestBody.content?.["application/json"]?.schema ?? {},
                            null, 2,
                          )}
                        </pre>
                      </div>
                    )}

                    {ep.responses && (
                      <div>
                        <div style={{ fontWeight: 600, marginBottom: 6, fontSize: 12 }}>Responses</div>
                        <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                          {Object.entries(ep.responses).map(([code, resp]) => (
                            <div key={code} style={{ display: "flex", gap: 10, alignItems: "center" }}>
                              <span style={{
                                fontSize: 11, fontWeight: 700, padding: "1px 6px", borderRadius: 4,
                                background: code.startsWith("2") ? "var(--success)22" : "var(--error)22",
                                color: code.startsWith("2") ? "var(--success)" : "var(--error)",
                              }}>
                                {code}
                              </span>
                              <span style={{ fontSize: 12, color: "var(--text-muted)" }}>{resp.description}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      ))}

      {!loading && !error && filtered.length === 0 && (
        <div style={{ color: "var(--text-muted)", fontSize: 13, padding: "20px 0" }}>
          No endpoints match your filter.
        </div>
      )}
    </div>
  );
}
