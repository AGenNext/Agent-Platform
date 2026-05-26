import { test, expect } from '@playwright/test';
import { createObjective, createArtifact, apiHeaders } from './helpers';

const TS = Date.now();

test.describe('Artifacts View', () => {
  test.beforeAll(async ({ request }) => {
    // Seed at least one artifact so the expand tests have something to work with
    const obj = await createObjective(request, `UI-artifact-obj-${TS}`);
    const objId = obj.id;
    await createArtifact(request, objId, `UI-artifact-${TS}`);

    // Evaluate the artifact so the eval panel appears when expanded
    const bareArtifact = objId; // we'll re-fetch via list
    const listRes = await request.get('/api/artifacts', { headers: apiHeaders() });
    const artifacts = await listRes.json();
    const artifact = artifacts.find((a: { title: string }) => a.title === `UI-artifact-${TS}`);
    if (artifact) {
      await request.post('/api/eval/evaluate', {
        data: {
          artifact_id: artifact.id,
          dimension_scores: { completeness: 0.9, logical: 0.85, evidence: 0.8, accuracy: 0.9, relevance: 0.88 },
          rationale: 'Playwright seed eval',
          threshold: 0.70,
        },
        headers: apiHeaders(),
      });
      await request.post('/api/trust/provenance', {
        data: {
          artifact_id: artifact.id,
          evidence_links: [
            { source_ref: 'arxiv.org/abs/2501.00001', extract: 'benchmark data', step_description: 'research' },
            { source_ref: 'arxiv.org/abs/2501.00002', extract: 'eval scores', step_description: 'scoring' },
            { source_ref: 'openai.com/research', extract: 'GPT results', step_description: 'comparison' },
          ],
        },
        headers: apiHeaders(),
      });
    }
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Artifacts' }).click();
    await expect(page.locator('header').getByText('Artifacts')).toBeVisible();
  });

  // ── Layout ─────────────────────────────────────────────────────────────────

  test('Artifacts heading is visible', async ({ page }) => {
    await expect(page.getByText('Artifacts')).toBeVisible();
  });

  test('list renders without crashing after data loads', async ({ page }) => {
    await page.waitForTimeout(3_000);
    const hasItems = await page.locator('[class*="rounded-lg"]').count() > 0;
    const hasEmpty = await page.getByText('No artifacts yet').isVisible();
    expect(hasItems || hasEmpty).toBe(true);
  });

  // ── Seeded artifact ─────────────────────────────────────────────────────────

  test('seeded artifact title is visible', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
  });

  test('artifact row shows artifact_type badge', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('report').first()).toBeVisible();
  });

  test('artifact row shows status badge', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('draft').first()).toBeVisible();
  });

  // ── Expand / collapse ───────────────────────────────────────────────────────

  test('clicking artifact row expands it to show details', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    // The row is a button — click it
    await page.getByText(`UI-artifact-${TS}`).click();
    // Expanded state shows ID and Objective fields
    await expect(page.getByText(/^ID:/)).toBeVisible({ timeout: 5_000 });
  });

  test('clicking expanded row collapses it', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    await page.getByText(`UI-artifact-${TS}`).click();
    await expect(page.getByText(/^ID:/)).toBeVisible();
    // Click again to collapse
    await page.getByText(`UI-artifact-${TS}`).click();
    await expect(page.getByText(/^ID:/)).not.toBeVisible();
  });

  test('expanded artifact shows CLEAR eval result', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    await page.getByText(`UI-artifact-${TS}`).click();
    // Wait for eval to load
    await expect(page.getByText('CLEAR Eval')).toBeVisible({ timeout: 8_000 });
    await expect(page.getByText('passed').first()).toBeVisible();
  });

  test('CLEAR eval shows all five dimension scores', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    await page.getByText(`UI-artifact-${TS}`).click();
    await expect(page.getByText('CLEAR Eval')).toBeVisible({ timeout: 8_000 });
    // Dimension abbreviations: Comp, Logi, Evid, Accu, Rele
    for (const dim of ['Comp', 'Logi', 'Evid', 'Accu', 'Rele']) {
      await expect(page.getByText(dim)).toBeVisible();
    }
  });

  test('expanded artifact shows trust score bar', async ({ page }) => {
    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    await page.getByText(`UI-artifact-${TS}`).click();
    await expect(page.getByText('Trust')).toBeVisible({ timeout: 8_000 });
    // Trust bar is rendered as a progress-bar-like div
    await expect(page.locator('.bg-indigo-500').first()).toBeVisible();
  });

  test('multiple artifacts can be expanded independently', async ({ page, request }) => {
    // Create a second artifact
    const obj = await createObjective(request, `UI-multi-obj-${TS}`);
    await createArtifact(request, obj.id, `UI-multi-${TS}`);
    await page.reload();
    await page.getByRole('button', { name: 'Artifacts' }).click();

    await expect(page.getByText(`UI-artifact-${TS}`)).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText(`UI-multi-${TS}`)).toBeVisible({ timeout: 10_000 });

    // Expand first
    await page.getByText(`UI-artifact-${TS}`).click();
    await expect(page.getByText(/^ID:/)).toBeVisible();

    // Expand second — first should auto-collapse (only one expanded at a time)
    await page.getByText(`UI-multi-${TS}`).click();
    const idBlocks = await page.getByText(/^ID:/).count();
    expect(idBlocks).toBe(1);
  });
});
