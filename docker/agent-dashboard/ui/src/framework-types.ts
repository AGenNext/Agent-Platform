/**
 * Formal TypeScript types for every external framework referenced by RealGraph.
 * Derived directly from each framework's specification — no omissions.
 * The platform will evaluate all of these; no choices have been made yet.
 */

// ── CLEAR Evaluation Rubric ──────────────────────────────────────────────────
// Source: RealGraph evaluation framework aligned with Ragas, G-Eval, Chang et al. 2023

export type CLEARDimension = 'completeness' | 'logical' | 'evidence' | 'accuracy' | 'relevance'

export interface CLEARDimensionScore {
  dimension: CLEARDimension
  score: number          // 0.0 – 1.0
  weight: number         // default 0.20
  rationale?: string
  source_grounding_applied: boolean  // true if evidence was capped due to missing provenance
}

export interface CLEAREval {
  id: string
  artifact_id: string
  rubric_id?: string
  completeness: number
  logical: number
  evidence: number
  accuracy: number
  relevance: number
  weights: Record<CLEARDimension, number>
  composite_score: number
  passed: boolean
  threshold: number
  source_grounding_enforced: boolean
  rationale?: string
  evaluated_at: string
}

// ── FinOps Foundation FOCUS Model ───────────────────────────────────────────
// Source: FinOps Open Cost & Usage Specification v1.0 — https://focus.finops.org

export interface FinOpsRecord {
  id: string
  billing_account_id: string
  billing_period_start: string
  billing_period_end: string
  service_name: string             // e.g. "anthropic", "ollama"
  service_category: string         // e.g. "AI and Machine Learning"
  sku_id: string                   // model_id
  sku_price_id?: string
  usage_type: 'input_tokens' | 'output_tokens' | string
  usage_quantity: number
  usage_unit: string               // "tokens"
  list_unit_price: number
  list_cost: number
  effective_cost: number
  billed_cost: number
  resource_id?: string             // objective_id
  resource_name?: string
  region_id?: string
  tags: Record<string, string>     // { objective_id, workspace_id, ... }
  charge_period_start: string
}

export interface FinOpsSummary {
  total_effective_cost: number
  total_billed_cost: number
  total_usage_quantity: number
  by_service: Record<string, number>
  by_sku: Record<string, number>
  by_resource: Record<string, number>
}

// ── Google A2A Protocol ──────────────────────────────────────────────────────
// Source: Google Agent-to-Agent Protocol v0.2 — https://google.github.io/A2A

export type A2ATaskState =
  | 'submitted'
  | 'working'
  | 'input-required'
  | 'completed'
  | 'failed'
  | 'canceled'
  | 'unknown'

export interface A2ATextPart  { type: 'text'; text: string; metadata?: Record<string, unknown> }
export interface A2AFilePart  { type: 'file'; file: { name?: string; mimeType?: string; bytes?: string; uri?: string }; metadata?: Record<string, unknown> }
export interface A2ADataPart  { type: 'data'; data: Record<string, unknown>; metadata?: Record<string, unknown> }
export type A2APart = A2ATextPart | A2AFilePart | A2ADataPart

export interface A2AMessage {
  role: 'user' | 'agent'
  parts: A2APart[]
  metadata?: Record<string, unknown>
}

export interface A2ATaskStatus {
  state: A2ATaskState
  message?: A2AMessage
  timestamp: string
}

export interface A2AArtifact {
  name?: string
  description?: string
  parts: A2APart[]
  index: number
  append?: boolean
  lastChunk?: boolean
  metadata?: Record<string, unknown>
}

export interface A2ATask {
  id: string
  sessionId?: string
  status: A2ATaskStatus
  history?: A2AMessage[]
  artifacts?: A2AArtifact[]
  metadata?: Record<string, unknown>
  created_at: string
  updated_at: string
}

export interface A2AAgentSkill {
  id: string
  name: string
  description?: string
  tags?: string[]
  examples?: string[]
  inputModes?: string[]
  outputModes?: string[]
}

export interface A2AAgentCapabilities {
  streaming?: boolean
  pushNotifications?: boolean
  stateTransitionHistory?: boolean
}

export interface A2AAgentCard {
  name: string
  description?: string
  url: string
  version: string
  capabilities: A2AAgentCapabilities
  skills: A2AAgentSkill[]
  defaultInputModes: string[]
  defaultOutputModes: string[]
  authentication?: Record<string, unknown>
  provider?: { organization?: string; url?: string }
}

// ── LangGraph Checkpoint Model ───────────────────────────────────────────────
// Source: LangChain LangGraph — BaseCheckpointSaver interface
//         https://langchain-ai.github.io/langgraph/concepts/persistence/

export interface LangGraphCheckpoint {
  id: string
  thread_id: string
  checkpoint_ns: string
  checkpoint_id: string
  parent_checkpoint_id?: string
  type: string
  channel_values: Record<string, unknown>
  channel_versions: Record<string, unknown>
  versions_seen: Record<string, unknown>
  pending_sends: unknown[]
  created_at: string
}

export interface LangGraphCheckpointWrite {
  id: string
  thread_id: string
  checkpoint_ns: string
  checkpoint_id: string
  task_id: string
  idx: number
  channel: string
  type: string
  blob: string
  created_at: string
}

export interface LangGraphConfig {
  configurable: {
    thread_id: string
    checkpoint_ns?: string
    checkpoint_id?: string
  }
}

// ── W3C PROV-DM Provenance Model ─────────────────────────────────────────────
// Source: W3C PROV Data Model — https://www.w3.org/TR/prov-dm/

export interface ProvEntity {
  id: string
  entity_id: string
  entity_type: 'artifact' | 'source' | 'dataset' | string
  label?: string
  location?: string       // source_ref / URI
  value?: Record<string, unknown>
  generated_at_time?: string
  invalidated_at_time?: string
  attributes: Record<string, unknown>
  recorded_at: string
}

export interface ProvActivity {
  id: string
  activity_id: string
  activity_type: string
  label?: string
  started_at_time?: string
  ended_at_time?: string
  attributes: Record<string, unknown>
  recorded_at: string
}

export interface ProvAgent {
  id: string
  agent_id: string
  agent_type: 'SoftwareAgent' | 'Person' | 'Organization'
  label?: string
  attributes: Record<string, unknown>
  recorded_at: string
}

export interface ProvWasGeneratedBy {
  id: string
  entity_id: string
  activity_id: string
  agent_id?: string
  generated_at_time?: string
  role?: string
}

export interface ProvWasDerivedFrom {
  id: string
  generated_entity: string
  used_entity: string
  activity_id?: string
  generation_id?: string
  usage_id?: string
}

export interface ProvUsed {
  id: string
  activity_id: string
  entity_id: string
  used_at_time?: string
  role?: string
  attributes: Record<string, unknown>
}

export interface ProvWasAttributedTo {
  id: string
  entity_id: string
  agent_id: string
  attributes: Record<string, unknown>
}

// ── OpenTelemetry Span Model ──────────────────────────────────────────────────
// Source: OpenTelemetry Specification — https://opentelemetry.io/docs/specs/otel/
// Aligned with OTLP data model for traces.

export type OTelSpanKind = 'UNSPECIFIED' | 'INTERNAL' | 'SERVER' | 'CLIENT' | 'PRODUCER' | 'CONSUMER'
export type OTelStatusCode = 'UNSET' | 'OK' | 'ERROR'

export interface OTelSpanEvent {
  time_unix_nano: number
  name: string
  attributes: Record<string, unknown>
  dropped_attributes_count?: number
}

export interface OTelSpanLink {
  trace_id: string
  span_id: string
  trace_state?: string
  attributes: Record<string, unknown>
  dropped_attributes_count?: number
}

export interface OTelSpan {
  id: string
  trace_id: string
  span_id: string
  parent_span_id?: string
  trace_state?: string
  name: string
  span_kind: OTelSpanKind
  start_time_unix_nano: number
  end_time_unix_nano: number
  attributes: Record<string, unknown>
  events: OTelSpanEvent[]
  links: OTelSpanLink[]
  status_code: OTelStatusCode
  status_message?: string
  dropped_attributes_count: number
  dropped_events_count: number
  dropped_links_count: number
  resource_attributes: Record<string, unknown>
  scope_name?: string
  scope_version?: string
}
