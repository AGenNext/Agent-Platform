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

export const api = {
  health(): Promise<HealthResponse> {
    return request<HealthResponse>("/health");
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
