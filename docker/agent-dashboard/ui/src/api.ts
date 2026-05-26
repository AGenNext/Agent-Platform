const BASE = '/api'

async function req<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}`)
  return res.json()
}

async function reqForm<T>(path: string, formData: FormData): Promise<T> {
  const res = await fetch(`${BASE}${path}`, { method: 'POST', body: formData })
  if (!res.ok) throw new Error(`POST ${path} → ${res.status}`)
  return res.json()
}

export const api = {
  health: () => req<HealthStatus>('GET', '/health'),
  mapContext: (query: string, workspaceId?: string, topKbs?: number) =>
    req<ContextMap>('POST', '/context-map', { query, workspace_id: workspaceId, top_kbs: topKbs }),
  ingestText: (kbId: string, payload: { text: string; source_label?: string; source_ref?: string; strategy?: string; chunk_size?: number; chunk_overlap?: number }) =>
    req<IngestResult>('POST', `/knowledge-bases/${kbId}/ingest/text`, payload),
  ingestFile: (kbId: string, file: File, opts: { source_label?: string; strategy?: string; chunk_size?: number }) => {
    const fd = new FormData()
    fd.append('file', file)
    if (opts.source_label) fd.append('source_label', opts.source_label)
    if (opts.strategy)     fd.append('strategy', opts.strategy)
    if (opts.chunk_size)   fd.append('chunk_size', String(opts.chunk_size))
    return reqForm<IngestResult>(`/knowledge-bases/${kbId}/ingest/file`, fd)
  },
  previewChunks: (text: string, strategy?: string, chunkSize?: number, overlap?: number) =>
    req<{ chunks: PreviewChunk[] }>('POST', '/knowledge-bases/ingest/preview', {
      text, strategy, chunk_size: chunkSize, chunk_overlap: overlap,
    }),
  listKnowledgeBases: (workspaceId?: string) =>
    req<KnowledgeBase[]>('GET', `/knowledge-bases${workspaceId ? `?workspace_id=${workspaceId}` : ''}`),
  createKnowledgeBase: (payload: { name: string; description?: string; kb_type?: string; workspace_id?: string }) =>
    req<KnowledgeBase>('POST', '/knowledge-bases', payload),
  listChunks: (kbId: string) =>
    req<KbChunk[]>('GET', `/knowledge-bases/${kbId}/chunks`),
  addChunk: (kbId: string, payload: { content: string; source_ref?: string; source_label?: string; seq?: number }) =>
    req<KbChunk>('POST', `/knowledge-bases/${kbId}/chunks`, payload),
  searchKb: (kbId: string, query: string) =>
    req<KbChunk[]>('POST', `/knowledge-bases/${kbId}/search`, { query }),
  generateArtifact: (payload: { objective_id: string; artifact_type: string; kb_ids: string[]; topic: string; instructions?: string; chunk_limit?: number }) =>
    req<ArtifactJob>('POST', '/generate', payload),
  getJob: (jobId: string) =>
    req<ArtifactJob>('GET', `/generate/jobs/${jobId}`),
  listJobs: (objectiveId: string) =>
    req<ArtifactJob[]>('GET', `/generate/objective/${objectiveId}/jobs`),
  buildGraph: (kbId: string) =>
    req<GraphStats>('POST', `/knowledge-bases/${kbId}/graph/build`),
  getGraphStats: (kbId: string) =>
    req<GraphStats>('GET', `/knowledge-bases/${kbId}/graph`),
  listEntities: (kbId: string) =>
    req<KbEntity[]>('GET', `/knowledge-bases/${kbId}/entities`),
  listCommunities: (kbId: string) =>
    req<KbCommunity[]>('GET', `/knowledge-bases/${kbId}/communities`),
  graphSearch: (payload: { query: string; kb_ids: string[]; mode?: string; chunk_limit?: number }) =>
    req<GraphSearchResult>('POST', '/knowledge-bases/graph/search', payload),
  listTenants: () => req<Tenant[]>('GET', '/tenants'),
  createTenant: (payload: { name: string; plan?: string }) =>
    req<Tenant>('POST', '/tenants', payload),
  getTenant: (id: string) => req<Tenant>('GET', `/tenants/${id}`),
  listUsers: (tenantId: string) => req<TenantUser[]>('GET', `/tenants/${tenantId}/users`),
  createUser: (tenantId: string, payload: { email: string; role?: string; display_name?: string }) =>
    req<TenantUser>('POST', `/tenants/${tenantId}/users`, payload),
  listApiKeys: (tenantId: string) => req<ApiKey[]>('GET', `/tenants/${tenantId}/api-keys`),
  createApiKey: (tenantId: string, payload: { name: string; scopes?: string[] }) =>
    req<ApiKey>('POST', `/tenants/${tenantId}/api-keys`, payload),
  revokeApiKey: (tenantId: string, keyId: string) =>
    req<void>('DELETE', `/tenants/${tenantId}/api-keys/${keyId}`),
  getBilling: (tenantId: string) => req<BillingSubscription>('GET', `/tenants/${tenantId}/billing`),
  changePlan: (tenantId: string, plan: string) =>
    req<BillingSubscription>('POST', `/tenants/${tenantId}/billing/plan`, { plan }),
  listAuditLogs: (tenantId: string, action?: string, limit?: number) =>
    req<AuditLog[]>('GET', `/tenants/${tenantId}/audit-logs${action ? `?action=${action}` : ''}${limit ? `&limit=${limit}` : ''}`),
  listTrends: (artifactType?: string, modelId?: string) =>
    req<EvalTrend[]>('GET', `/analytics/trends${artifactType ? `?artifact_type=${artifactType}` : ''}`),
  computeTrends: (days = 7) =>
    req<EvalTrend[]>('POST', `/analytics/trends/compute?days=${days}`),
  listSuggestions: (status?: string) =>
    req<RoutingSuggestion[]>('GET', `/analytics/suggestions${status ? `?status=${status}` : ''}`),
  analyseSuggestions: () =>
    req<RoutingSuggestion[]>('POST', '/analytics/suggestions/analyse'),
  resolveSuggestion: (id: string, action: 'applied' | 'dismissed') =>
    req<RoutingSuggestion>('POST', `/analytics/suggestions/${id}/resolve?action=${action}`),
  listBenchmarks: () =>
    req<BenchmarkDef[]>('GET', '/analytics/benchmarks'),
  createBenchmark: (payload: { name: string; artifact_type: string; test_cases: unknown[]; description?: string }) =>
    req<BenchmarkDef>('POST', '/analytics/benchmarks', payload),
  runBenchmark: (benchmarkId: string) =>
    req<BenchmarkRun>('POST', `/analytics/benchmarks/${benchmarkId}/run`, {}),
  listBenchmarkRuns: (benchmarkId?: string) =>
    benchmarkId
      ? req<BenchmarkRun[]>('GET', `/analytics/benchmarks/${benchmarkId}/runs`)
      : req<BenchmarkRun[]>('GET', '/analytics/runs'),
  listObjectives: (status?: string) =>
    req<Objective[]>('GET', `/objectives${status ? `?status=${status}` : ''}`),
  createObjective: (payload: { title: string; objective_type: string; payload?: unknown }) =>
    req<Objective>('POST', '/objectives', payload),
  runObjective: (id: string) =>
    req<{ objective_id: string; status: string }>('POST', `/objectives/${id}/run`),
  listArtifacts: (objectiveId?: string) =>
    req<Artifact[]>('GET', `/artifacts${objectiveId ? `?objective_id=${objectiveId}` : ''}`),
  listAgents: (runId: string) =>
    req<Agent[]>('GET', `/agents/run/${runId}`),
  getHandoffChain: (agentId: string) =>
    req<HandoffLink[]>('GET', `/agents/${agentId}/handoff/chain`),
  evalResult: (artifactId: string) =>
    req<EvalResult>('GET', `/eval/artifacts/${artifactId}`),
  trustScore: (artifactId: string) =>
    req<TrustScore>('GET', `/trust/artifacts/${artifactId}`),
  usageSummary: () =>
    req<UsageSummary>('GET', '/model-router/usage/summary'),
}

export interface HealthStatus {
  status: 'ok' | 'degraded'
  service: string
  version: string
  surrealdb: string
  env: string
}

export interface Objective {
  id: string
  title: string
  objective_type: string
  status: string
  created_at: string
  updated_at: string
  payload?: unknown
}

export interface Artifact {
  id: string
  title: string
  artifact_type: string
  status: string
  objective_id: string
  created_at: string
  content_ref?: string
}

export interface Agent {
  id: string
  run_id: string
  agent_role: string
  status: string
  created_at: string
}

export interface HandoffLink {
  id: string
  source_agent_id: string
  target_agent_id: string
  context: string
  handoff_status: string
  created_at: string
}

export interface EvalResult {
  artifact_id: string
  composite_score: number
  passed: boolean
  threshold: number
  dimension_scores: Record<string, number>
  rationale?: string
}

export interface TrustScore {
  artifact_id: string
  score: number
  evidence_count: number
  passed?: boolean
}

export interface Tenant {
  id: string
  name: string
  slug: string
  plan: string
  status: string
  created_at: string
}

export interface TenantUser {
  id: string
  tenant_id: string
  email: string
  display_name: string
  role: string
  status: string
  last_active?: string
  created_at: string
}

export interface ApiKey {
  id: string
  tenant_id: string
  name: string
  key_prefix: string
  scopes: string[]
  status: string
  last_used_at?: string
  created_at: string
  raw_key?: string
}

export interface BillingSubscription {
  id: string
  tenant_id: string
  plan_id: string
  status: string
  current_period_start: string
  current_period_end?: string
  limits?: Record<string, number>
}

export interface AuditLog {
  id: string
  tenant_id: string
  actor_id?: string
  actor_type: string
  action: string
  resource_type?: string
  resource_id?: string
  result: string
  metadata?: Record<string, unknown>
  occurred_at: string
}

export interface KnowledgeBase {
  id: string
  name: string
  description: string
  kb_type: string
  workspace_id?: string
  chunk_count: number
  created_at: string
  updated_at: string
}

export interface KbChunk {
  id: string
  kb_id: string
  content: string
  source_ref?: string
  source_label?: string
  seq: number
  metadata?: Record<string, unknown>
  created_at: string
}

export interface GraphStats {
  kb_id: string
  entity_count: number
  relation_count: number
  community_count: number
}

export interface KbEntity {
  id: string
  kb_id: string
  name: string
  entity_type: string
  description?: string
  chunk_ids: string[]
  mention_count: number
}

export interface KbCommunity {
  id: string
  kb_id: string
  community_idx: number
  title?: string
  summary?: string
  entity_names: string[]
  entity_count: number
}

export interface GraphSearchResult {
  mode: string
  chunks: KbChunk[]
  entities?: KbEntity[]
  communities?: KbCommunity[]
  has_graph?: boolean
}

export interface ArtifactJob {
  id: string
  objective_id: string
  artifact_type: string
  kb_ids: string[]
  topic: string
  instructions?: string
  status: 'pending' | 'running' | 'complete' | 'failed'
  artifact_id?: string
  chunks_used: string[]
  model_used?: string
  error?: string
  created_at: string
  completed_at?: string
}

export interface UsageSummary {
  total_calls: number
  total_input_tokens: number
  total_output_tokens: number
  total_cost_usd: number
  avg_cost_usd: number
}

export interface EvalTrend {
  id: string
  period_date: string
  artifact_type: string
  model_id?: string
  avg_score: number
  min_score: number
  max_score: number
  sample_count: number
  computed_at: string
}

export interface RoutingSuggestion {
  id: string
  task_type?: string
  current_weights: Record<string, number>
  suggested_weights: Record<string, number>
  rationale: string
  evidence?: {
    model_id?: string
    avg_eval_score?: number
    avg_latency_ms?: number
    avg_cost_usd?: number
    sample_count?: number
  }
  status: 'pending' | 'applied' | 'dismissed'
  created_at: string
  resolved_at?: string
}

export interface BenchmarkDef {
  id: string
  name: string
  description?: string
  artifact_type: string
  test_cases: Array<{ topic: string; kb_ids?: string[]; min_eval_score?: number }>
  baseline_score?: number
  regression_threshold: number
  created_at: string
}

export interface BenchmarkRun {
  id: string
  benchmark_id: string
  status: 'running' | 'passed' | 'failed' | 'regressed'
  avg_score?: number
  baseline_score?: number
  delta?: number
  regression?: boolean
  model_id?: string
  case_results?: Array<{ topic: string; artifact_id?: string; eval_score: number; min_score: number; passed: boolean; error?: string }>
  started_at?: string
  completed_at?: string
}

export interface KbContextEntry {
  kb_id: string
  kb_name: string
  kb_type: string
  chunk_count: number
  has_graph: boolean
  relevance_score: number
  matched_entity_count: number
  matched_community_count: number
  matched_chunk_count: number
  top_entities: Array<{ name: string; entity_type: string; description?: string }>
  top_communities: Array<{ title?: string; summary?: string; entity_count: number }>
  top_chunks: Array<{ preview: string; source_label: string }>
}

export interface ContextMap {
  query: string
  kb_maps: KbContextEntry[]
  cross_links: Array<{ entity_name: string; kb_ids: string[]; kb_names: string[] }>
  suggested_kb_ids: string[]
}

export interface IngestResult {
  kb_id: string
  chunks_stored: number
  chunks_skipped: number
  total_input_chunks: number
  source_label: string
}

export interface PreviewChunk {
  seq: number
  content: string
  char_count: number
}
