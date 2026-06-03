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
  listSpaces: () => req<Space[]>('GET', '/spaces'),
  listChannels: () => req<Channel[]>('GET', '/channels'),
  listMilestones: () => req<Milestone[]>('GET', '/milestones'),
  agentRoster: () => req<AgentProfile[]>('GET', '/agents/roster'),
  gatewayRoutes: () => req<ModelRoute[]>('GET', '/model-router/routes'),
  hubArtifacts: () => req<HubArtifact[]>('GET', '/artifacts/hub'),
  learningPaths: () => req<LearningPath[]>('GET', '/learning/paths'),
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

export interface Space {
  id: string
  name: string
  owner: string
  description: string
  status: string
  kind: 'research' | 'generation' | 'eval' | 'generic'
  runs: number
  artifacts: number
  trust: number
  updated_at: string
}

export interface Channel {
  id: string
  name: string
  kind: 'agent' | 'system' | 'human'
  unread: number
  last_message: string
  last_at: string
  active: boolean
}

export interface ModelRoute {
  id: string
  provider: string
  model: string
  requests: number
  cost_usd: number
  p95_ms: number
  error_rate: number
  share: number
  status: string
}

export interface HubArtifact {
  id: string
  title: string
  artifact_type: 'deck' | 'doc' | 'dataset' | 'code' | 'report'
  space: string
  version: string
  eval_score: number
  trust: number
  status: string
  downloads: number
  updated_at: string
}

export interface LearningModule {
  title: string
  done: boolean
}

export interface LearningPath {
  id: string
  title: string
  description: string
  level: 'Beginner' | 'Intermediate' | 'Advanced'
  duration_min: number
  enrolled: number
  progress: number
  modules: LearningModule[]
}

export interface AgentProfile {
  id: string
  role: string
  status: string
  model: string
  space: string
  skills: string[]
  current_task?: string
  runs: number
  trust: number
}

export interface Milestone {
  id: string
  name: string
  space: string
  status: string
  progress: number
  due_at: string
  tasks_done: number
  tasks_total: number
  owner: string
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

export interface UsageSummary {
  total_calls: number
  total_input_tokens: number
  total_output_tokens: number
  total_cost_usd: number
  avg_cost_usd: number
}
