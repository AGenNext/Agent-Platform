const BASE = "/api";

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`${res.status} ${res.statusText}: ${body}`);
  }
  return res.json() as Promise<T>;
}

export interface HealthResponse {
  status: string;
  service: string;
  version: string;
  db: string;
}

export interface AgentRegistration {
  name: string;
  tenant_id: string;
  description?: string;
  version?: string;
  goal_types?: string[];
  skill_ids?: string[];
  capabilities: Record<string, boolean>;
}

export interface AgentRecord {
  id: string;
  agent_id: string;
  name: string;
  description?: string;
  version: string;
  tenant_id: string;
  status: string;
  capabilities: Record<string, boolean>;
  goal_types: string[];
  skill_ids: string[];
  registered_at: string;
  last_seen_at: string;
}

export interface ObjectiveRequest {
  goal: string;
  context?: Record<string, unknown>;
  priority?: number;
  schema_type?: string;
}

export interface JsonLd {
  "@context": string;
  "@type": string;
  "@id": string;
  name: string;
  description: string;
  actionStatus: string;
  startTime: string;
  endTime: string;
  result: Record<string, unknown> | null;
  _meta: Record<string, unknown>;
}

export interface ObjectiveRecord {
  id: string;
  "@context": string;
  "@type": string;
  goal: string;
  name: string;
  description: string;
  agent_context: Record<string, unknown>;
  priority: number;
  status: "pending" | "running" | "completed" | "failed";
  created_at: string;
  updated_at: string;
  result: Record<string, unknown> | null;
  error: string | null;
}

export interface ObjectiveResponse {
  objective: ObjectiveRecord;
  jsonld: JsonLd;
  message: string;
}

export interface BlueprintRecord {
  id: string;
  blueprint_id: string;
  name: string;
  description?: string;
  goal_types: string[];
  skill_ids: string[];
  capabilities: Record<string, boolean>;
  cost_limit_usd: number;
  graph_node?: string;
  version: string;
  active: boolean;
}

export interface SkillRecord {
  id: string;
  skill_id: string;
  name: string;
  category: string;
}

export interface MemoryCreate {
  agent_id: string;
  tenant_id: string;
  content: string;
  memory_type?: string;
  importance?: number;
  tags?: string[];
  embedding?: number[];
}

export interface MemorySearchRequest {
  agent_id: string;
  tenant_id: string;
  query: string;
  memory_type?: string;
  limit?: number;
  query_embedding?: number[];
}

export interface MemoryRecord {
  id: string;
  agent_id: string;
  tenant_id: string;
  content: string;
  summary?: string;
  memory_type: string;
  importance: number;
  tags: string[];
  access_count: number;
  created_at: string;
}

export const api = {
  health(): Promise<HealthResponse> {
    return request<HealthResponse>("/health");
  },
  registerAgent(body: AgentRegistration): Promise<AgentRecord> {
    return request<AgentRecord>("/agents/register", {
      method: "POST",
      body: JSON.stringify(body),
    });
  },
  listAgents(params?: { tenant_id?: string; status?: string }): Promise<AgentRecord[]> {
    const q = new URLSearchParams(params as Record<string, string>).toString();
    return request<AgentRecord[]>(`/agents/${q ? `?${q}` : ""}`);
  },
  listBlueprints(): Promise<BlueprintRecord[]> {
    return request<BlueprintRecord[]>("/blueprints/");
  },
  listSkills(category?: string): Promise<SkillRecord[]> {
    const q = category ? `?category=${encodeURIComponent(category)}` : "";
    return request<SkillRecord[]>(`/skills/${q}`);
  },
  storeMemory(body: MemoryCreate): Promise<MemoryRecord> {
    return request<MemoryRecord>("/memory/", {
      method: "POST",
      body: JSON.stringify(body),
    });
  },
  searchMemory(body: MemorySearchRequest): Promise<MemoryRecord[]> {
    return request<MemoryRecord[]>("/memory/search", {
      method: "POST",
      body: JSON.stringify(body),
    });
  },
  getAgentMemory(agentId: string, tenantId: string, params?: { memory_type?: string; limit?: number }): Promise<MemoryRecord[]> {
    const q = new URLSearchParams({ tenant_id: tenantId, ...(params ?? {}) } as Record<string, string>).toString();
    return request<MemoryRecord[]>(`/memory/${encodeURIComponent(agentId)}?${q}`);
  },
  runObjective(body: ObjectiveRequest): Promise<ObjectiveResponse> {
    return request<ObjectiveResponse>("/objectives/run", {
      method: "POST",
      body: JSON.stringify(body),
    });
  },
  listObjectives(): Promise<ObjectiveRecord[]> {
    return request<ObjectiveRecord[]>("/objectives/");
  },
  getObjective(id: string): Promise<ObjectiveRecord> {
    return request<ObjectiveRecord>(`/objectives/${id}`);
  },
};
