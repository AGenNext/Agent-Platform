/**
 * Shared helpers for Playwright UI tests.
 * All API calls go through the dashboard proxy (/api/*) so the full
 * request path is exercised, not just the backend in isolation.
 */
import { APIRequestContext } from '@playwright/test';

const API_KEY = process.env.E2E_API_KEY || '';

export function apiHeaders(): Record<string, string> {
  const h: Record<string, string> = { 'Content-Type': 'application/json' };
  if (API_KEY) h['X-API-Key'] = API_KEY;
  return h;
}

export async function createObjective(
  request: APIRequestContext,
  title: string,
  type = 'research',
) {
  const res = await request.post('/api/objectives', {
    data: { title, objective_type: type },
    headers: apiHeaders(),
  });
  return res.json();
}

export async function createArtifact(
  request: APIRequestContext,
  objectiveId: string,
  title: string,
) {
  const res = await request.post('/api/artifacts', {
    data: {
      objective_id: objectiveId,
      artifact_type: 'report',
      title,
      content_ref: 'test://playwright',
    },
    headers: apiHeaders(),
  });
  return res.json();
}

export async function createWorkflowRun(
  request: APIRequestContext,
  objectiveId: string,
) {
  const res = await request.post('/api/workflows/runs', {
    data: { objective_id: objectiveId, initial_state: {} },
    headers: apiHeaders(),
  });
  return res.json();
}

export async function createAgent(
  request: APIRequestContext,
  runId: string,
  role: string,
) {
  const res = await request.post('/api/agents', {
    data: { run_id: runId, agent_role: role },
    headers: apiHeaders(),
  });
  return res.json();
}

export function bareId(fullId: string): string {
  return fullId.includes(':') ? fullId.split(':')[1] : fullId;
}
