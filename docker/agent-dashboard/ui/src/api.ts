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

export const api = {
  health: () => req<HealthStatus>('GET', '/health'),
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
