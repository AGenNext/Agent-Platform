import { Card } from "../components/Card";
import { StatusBadge } from "../components/StatusBadge";

// Integration catalog — all natively supported via SurrealDB schemas + adapters
// Status: active (schema loaded), available (adapter ready), planned
interface Integration {
  id: string;
  name: string;
  category: string;
  description: string;
  status: "active" | "available" | "planned";
  protocol?: string;
  schema?: string;
  docsUrl?: string;
}

const INTEGRATIONS: Integration[] = [
  // AI Frameworks
  { id: "langchain",     category: "AI Frameworks",  name: "LangChain",            description: "LangChain agent executor with SurrealDB memory and vector store", status: "available", protocol: "Python SDK", schema: "memory.surql" },
  { id: "langgraph",     category: "AI Frameworks",  name: "LangGraph",             description: "Stateful multi-agent graphs with SurrealDB state persistence", status: "available", protocol: "graph_node", schema: "blueprint.surql" },
  { id: "crewai",        category: "AI Frameworks",  name: "CrewAI",                description: "Crew-based agents using blueprint.surql for role definitions", status: "available", protocol: "blueprint", schema: "blueprint.surql" },
  { id: "autogen",       category: "AI Frameworks",  name: "AutoGen",               description: "Microsoft AutoGen agents with SurrealDB conversation memory", status: "planned", protocol: "Python SDK" },
  { id: "agno",          category: "AI Frameworks",  name: "Agno",                  description: "Agno agent framework with MTREE vector memory backend", status: "planned", protocol: "Python SDK" },
  // MCP
  { id: "mcp",           category: "MCP",             name: "Model Context Protocol", description: "MCP server that exposes SurrealDB tables as resources and tools", status: "active", protocol: "mcp", schema: "0043_mcp_compatibility_functions.surql" },
  // A2A
  { id: "a2a",           category: "A2A Protocol",    name: "Agent-to-Agent (A2A)",  description: "Google A2A protocol for agent handoff and task delegation", status: "active", protocol: "a2a", schema: "0035_a2a_protocol_support_functions.surql" },
  // Auth
  { id: "openid",        category: "Auth & Identity", name: "OpenID Connect",        description: "OIDC-based multi-tenant auth via DEFINE SCOPE + JWT", status: "active", protocol: "openid", schema: "auth.surql" },
  { id: "openfga",       category: "Auth & Identity", name: "OpenFGA",               description: "Relationship-based authorization with SurrealDB RELATE edges", status: "active", protocol: "fga", schema: "0034_openfga_relationship_authorization_functions.surql" },
  { id: "opa",           category: "Auth & Identity", name: "Open Policy Agent",     description: "OPA policy evaluation with SurrealDB policy table", status: "active", protocol: "opa", schema: "0033_open_policy_agent_integration_functions.surql" },
  // Commerce
  { id: "stripe",        category: "Commerce",        name: "Stripe",                description: "Payment processing via AP2 adapter — charges, subscriptions, invoices", status: "available", protocol: "ap2", schema: "commerce_checkout_payments.surql" },
  { id: "paypal",        category: "Commerce",        name: "PayPal",                description: "PayPal payments via OpenBanking adapter", status: "available", protocol: "ap2", schema: "commerce_checkout_payments.surql" },
  { id: "shopify",       category: "Commerce",        name: "Shopify",               description: "Shopify storefront — catalog, orders, fulfillment", status: "available", protocol: "shopify", schema: "commerce_catalog_onboarding.surql" },
  { id: "x402",          category: "Commerce",        name: "X402 (Crypto)",         description: "HTTP 402 payment protocol — AI agent micropayments", status: "available", protocol: "x402", schema: "commerce_checkout_payments.surql" },
  { id: "openbanking",   category: "Commerce",        name: "Open Banking",          description: "PSD2/OpenBanking bank account payments and settlements", status: "available", protocol: "openbanking", schema: "commerce_settlements_payouts.surql" },
  // Storage
  { id: "r2",            category: "Storage",         name: "Cloudflare R2",         description: "Object storage for artifacts — upload, download, presigned URLs", status: "active", protocol: "r2", schema: "0049_cloudflare_r2_object_storage_functions.surql" },
  // Observability
  { id: "otel",          category: "Observability",   name: "OpenTelemetry",         description: "Trace + span emission to trace table, compatible with Jaeger/Tempo", status: "active", protocol: "otel", schema: "trace.surql" },
  { id: "slo",           category: "Observability",   name: "SLO / Alerting",        description: "SLO tracking and alert emission via DEFINE EVENT", status: "active", schema: "0045_slo_incident_alerting_functions.surql" },
  { id: "siem",          category: "Observability",   name: "SIEM / Data Lake",      description: "Audit log streaming to SIEM or data lake via SurrealDB events", status: "available", schema: "0066_siem_data_lake_bigdata_object_storage_integrations.surql" },
  // Enterprise
  { id: "camunda",       category: "Enterprise",      name: "Camunda BPMN/DMN",      description: "Business process + decision model integration", status: "available", schema: "0059_camunda_bpmn_dmn_integration.surql" },
  { id: "hr",            category: "Enterprise",      name: "HR & Workforce",        description: "HR systems + SFIA skills framework integration", status: "available", schema: "0070_hr_workforce_skills_learning_integrations.surql" },
  { id: "iam",           category: "Enterprise",      name: "IAM / IGA / IdP",       description: "Enterprise IAM integration (Okta, AD, LDAP) via DEFINE SCOPE", status: "available", schema: "0061_business_app_integration_iam_iga_idp.surql" },
];

const CATEGORIES = [...new Set(INTEGRATIONS.map((i) => i.category))];

const STATUS_ORDER = { active: 0, available: 1, planned: 2 };

export function IntegrationsPage() {
  const counts = {
    active: INTEGRATIONS.filter((i) => i.status === "active").length,
    available: INTEGRATIONS.filter((i) => i.status === "available").length,
    planned: INTEGRATIONS.filter((i) => i.status === "planned").length,
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Integrations</h1>
        <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
          All integrations run natively through SurrealDB schemas and adapters — no separate middleware layer.
        </p>
      </div>

      {/* Summary */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
        <KpiCard label="Active" value={counts.active} color="var(--green)" sub="Schema loaded + enforced" />
        <KpiCard label="Available" value={counts.available} color="var(--accent)" sub="Adapter ready, env config needed" />
        <KpiCard label="Planned" value={counts.planned} color="var(--text-muted)" sub="On the roadmap" />
      </div>

      {/* Architecture note */}
      <Card title="Architecture">
        <div style={{ display: "flex", flexDirection: "column", gap: 10, fontSize: 13 }}>
          <p style={{ color: "var(--text-muted)", margin: 0 }}>
            Every integration is expressed as SurrealQL: <code>DEFINE TABLE</code> for state, <code>DEFINE EVENT</code> for reactions,
            <code style={{ marginLeft: 4 }}>RELATE</code> for graph edges, and <code>DEFINE FUNCTION</code> for business logic.
            Application adapters only handle protocol translation — all decisions stay in the DB.
          </p>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            {[
              { layer: "Auth",        impl: "DEFINE SCOPE + JWT → DEFINE PERMISSION tenant isolation" },
              { layer: "Analytics",   impl: "DEFINE EVENT → append-only event table, no external queue" },
              { layer: "Billing",     impl: "usage_record table + math::sum() GROUP BY → real-time ledger" },
              { layer: "Memory",      impl: "MTREE (vector) + BM25 (FTS) + RELATE (graph)" },
              { layer: "Commerce",    impl: "AP2 adapter → checkout_payments.surql + settlements" },
              { layer: "Observability", impl: "trace table (OTel spans) + DEFINE EVENT for SLO/alerts" },
            ].map((row) => (
              <div key={row.layer} style={{ padding: "8px 12px", borderRadius: 8, background: "var(--surface-2)", border: "1px solid var(--border)" }}>
                <div style={{ fontWeight: 600, fontSize: 12, color: "var(--accent)", marginBottom: 3 }}>{row.layer}</div>
                <div style={{ fontSize: 11, color: "var(--text-muted)" }}>{row.impl}</div>
              </div>
            ))}
          </div>
        </div>
      </Card>

      {/* Integration list by category */}
      {CATEGORIES.map((cat) => {
        const items = INTEGRATIONS
          .filter((i) => i.category === cat)
          .sort((a, b) => STATUS_ORDER[a.status] - STATUS_ORDER[b.status]);
        return (
          <Card key={cat} title={cat}>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {items.map((integration) => (
                <IntegrationRow key={integration.id} integration={integration} />
              ))}
            </div>
          </Card>
        );
      })}
    </div>
  );
}

function IntegrationRow({ integration: i }: { integration: Integration }) {
  return (
    <div style={{
      display: "flex", justifyContent: "space-between", alignItems: "flex-start",
      padding: "10px 12px", borderRadius: 8,
      background: "var(--surface-2)", border: "1px solid var(--border)",
      gap: 12,
      opacity: i.status === "planned" ? 0.6 : 1,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 3 }}>
          <span style={{ fontWeight: 600, fontSize: 13 }}>{i.name}</span>
          {i.protocol && (
            <span style={{ fontSize: 10, padding: "1px 6px", borderRadius: 4, background: "var(--bg)", color: "var(--accent)", border: "1px solid var(--border)", fontFamily: "monospace" }}>
              {i.protocol}
            </span>
          )}
        </div>
        <p style={{ margin: 0, fontSize: 12, color: "var(--text-muted)", lineHeight: 1.4 }}>{i.description}</p>
        {i.schema && (
          <code style={{ fontSize: 10, color: "var(--text-muted)", marginTop: 4, display: "block" }}>
            {i.schema}
          </code>
        )}
      </div>
      <StatusBadge status={i.status} />
    </div>
  );
}

function KpiCard({ label, value, color, sub }: { label: string; value: number; color: string; sub: string }) {
  return (
    <div style={{ background: "var(--surface-2)", border: `1px solid var(--border)`, borderTop: `3px solid ${color}`, borderRadius: 10, padding: "14px 18px" }}>
      <div style={{ fontSize: 11, color: "var(--text-muted)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 4 }}>{label}</div>
      <div style={{ fontSize: 28, fontWeight: 700, color }}>{value}</div>
      <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>{sub}</div>
    </div>
  );
}
