import { test, expect } from '@playwright/test';
import { createObjective, createWorkflowRun, createAgent, bareId, apiHeaders } from './helpers';

const TS = Date.now();

test.describe('A2A Trace Explorer', () => {
  let runId = '';
  let researcherId = '';
  let writerId = '';

  test.beforeAll(async ({ request }) => {
    // Set up a minimal workflow run with two agents and a handoff
    const obj = await createObjective(request, `UI-trace-obj-${TS}`);
    const run = await createWorkflowRun(request, obj.id);
    runId = run.id;

    const researcher = await createAgent(request, runId, 'researcher');
    researcherId = researcher.id;
    const writer = await createAgent(request, runId, 'writer');
    writerId = writer.id;

    // Create a handoff researcher → writer
    await request.post(`/api/agents/${bareId(researcherId)}/handoff`, {
      data: {
        target_agent_id: bareId(writerId),
        context: 'Research complete — handing off to writer',
        payload: {},
      },
      headers: apiHeaders(),
    });
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'A2A Trace' }).click();
    await expect(page.getByText('A2A Trace Explorer')).toBeVisible();
  });

  // ── Layout ─────────────────────────────────────────────────────────────────

  test('shows A2A Trace Explorer heading', async ({ page }) => {
    await expect(page.getByText('A2A Trace Explorer')).toBeVisible();
  });

  test('shows run ID input', async ({ page }) => {
    await expect(page.getByPlaceholder('Paste a workflow run ID...')).toBeVisible();
  });

  test('shows Trace button', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'Trace' })).toBeVisible();
  });

  test('Trace button is disabled when input is empty', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'Trace' })).toBeDisabled();
  });

  test('Trace button enables when run ID is typed', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill('some-run-id');
    await expect(page.getByRole('button', { name: 'Trace' })).toBeEnabled();
  });

  // ── Lookup ─────────────────────────────────────────────────────────────────

  test('looking up a valid run shows agent list', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText(/Agents \(/)).toBeVisible({ timeout: 10_000 });
  });

  test('shows researcher and writer agents after lookup', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('researcher')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('writer')).toBeVisible({ timeout: 10_000 });
  });

  test('pressing Enter in input triggers lookup', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByPlaceholder('Paste a workflow run ID...').press('Enter');
    await expect(page.getByText(/Agents \(/)).toBeVisible({ timeout: 10_000 });
  });

  test('agent count shown in Agents header', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('Agents (2)')).toBeVisible({ timeout: 10_000 });
  });

  test('Handoff Chain panel prompts to select an agent initially', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('Handoff Chain')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('Select an agent to view its handoff chain.')).toBeVisible();
  });

  test('clicking an agent loads its handoff chain', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('researcher')).toBeVisible({ timeout: 10_000 });
    await page.getByText('researcher').click();
    // Chain panel header updates
    await expect(page.getByText('Handoff Chain — researcher')).toBeVisible({ timeout: 8_000 });
  });

  test('handoff arrow is displayed in the chain', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('researcher')).toBeVisible({ timeout: 10_000 });
    await page.getByText('researcher').click();
    await expect(page.getByText('Handoff Chain — researcher')).toBeVisible({ timeout: 8_000 });
    // Writer is downstream via handoff
    await expect(page.getByText('writer')).toBeVisible({ timeout: 8_000 });
  });

  test('handoff context text is displayed', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('researcher')).toBeVisible({ timeout: 10_000 });
    await page.getByText('researcher').click();
    await expect(page.getByText(/Research complete/)).toBeVisible({ timeout: 8_000 });
  });

  test('unknown run ID shows an error message', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill('nonexistent-run-xyz-123');
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('No agents found for this run ID')).toBeVisible({ timeout: 8_000 });
  });

  test('agent status badge is displayed', async ({ page }) => {
    await page.getByPlaceholder('Paste a workflow run ID...').fill(runId);
    await page.getByRole('button', { name: 'Trace' }).click();
    await expect(page.getByText('researcher')).toBeVisible({ timeout: 10_000 });
    // Agents have status "idle" by default
    await expect(page.getByText('idle').first()).toBeVisible();
  });
});
