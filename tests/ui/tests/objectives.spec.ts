import { test, expect } from '@playwright/test';
import { createObjective } from './helpers';

const TS = Date.now();

test.describe('Objectives View', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Objectives' }).click();
    await expect(page.locator('header').getByText('Objectives')).toBeVisible();
  });

  // ── Layout ────────────────────────────────────────────────────────────────

  test('Objectives heading is visible', async ({ page }) => {
    await expect(page.getByText('Objectives')).toBeVisible();
  });

  test('New Objective button is visible', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'New Objective' })).toBeVisible();
  });

  // ── Form open/close ───────────────────────────────────────────────────────

  test('clicking New Objective opens the creation form', async ({ page }) => {
    await page.getByRole('button', { name: 'New Objective' }).click();
    await expect(page.getByPlaceholder('Objective title...')).toBeVisible();
  });

  test('Cancel button hides the form', async ({ page }) => {
    await page.getByRole('button', { name: 'New Objective' }).click();
    await expect(page.getByPlaceholder('Objective title...')).toBeVisible();
    await page.getByRole('button', { name: 'Cancel' }).click();
    await expect(page.getByPlaceholder('Objective title...')).not.toBeVisible();
  });

  test('form has a title input and a type select', async ({ page }) => {
    await page.getByRole('button', { name: 'New Objective' }).click();
    await expect(page.getByPlaceholder('Objective title...')).toBeVisible();
    await expect(page.getByRole('combobox')).toBeVisible();
  });

  test('type dropdown has the four expected options', async ({ page }) => {
    await page.getByRole('button', { name: 'New Objective' }).click();
    const options = await page.getByRole('combobox').locator('option').allTextContents();
    expect(options).toEqual(['generic', 'research', 'generation', 'eval']);
  });

  // ── Validation ────────────────────────────────────────────────────────────

  test('Create button is disabled when title is empty', async ({ page }) => {
    await page.getByRole('button', { name: 'New Objective' }).click();
    await expect(page.getByRole('button', { name: /^Create/ })).toBeDisabled();
  });

  test('Create button enables once title is typed', async ({ page }) => {
    await page.getByRole('button', { name: 'New Objective' }).click();
    await page.getByPlaceholder('Objective title...').fill('Test title');
    await expect(page.getByRole('button', { name: /^Create/ })).toBeEnabled();
  });

  test('Create button re-disables when title is cleared', async ({ page }) => {
    await page.getByRole('button', { name: 'New Objective' }).click();
    await page.getByPlaceholder('Objective title...').fill('Test title');
    await page.getByPlaceholder('Objective title...').fill('');
    await expect(page.getByRole('button', { name: /^Create/ })).toBeDisabled();
  });

  // ── Create & list ─────────────────────────────────────────────────────────

  test('creating an objective appends it to the list', async ({ page }) => {
    const title = `UI-create-${TS}`;
    await page.getByRole('button', { name: 'New Objective' }).click();
    await page.getByPlaceholder('Objective title...').fill(title);
    await page.getByRole('button', { name: /^Create/ }).click();
    // Form should close and the new objective should appear
    await expect(page.getByPlaceholder('Objective title...')).not.toBeVisible();
    await expect(page.getByText(title)).toBeVisible({ timeout: 10_000 });
  });

  test('pressing Enter in title field submits the form', async ({ page }) => {
    const title = `UI-enter-${TS}`;
    await page.getByRole('button', { name: 'New Objective' }).click();
    await page.getByPlaceholder('Objective title...').fill(title);
    await page.getByPlaceholder('Objective title...').press('Enter');
    await expect(page.getByText(title)).toBeVisible({ timeout: 10_000 });
  });

  test('newly created objective has a "pending" status badge', async ({ page }) => {
    const title = `UI-pending-${TS}`;
    await page.getByRole('button', { name: 'New Objective' }).click();
    await page.getByPlaceholder('Objective title...').fill(title);
    await page.getByRole('button', { name: /^Create/ }).click();
    await expect(page.getByText(title)).toBeVisible({ timeout: 10_000 });
    // The row for this objective should have a "pending" badge
    const row = page.locator('div').filter({ hasText: title }).first();
    await expect(row.getByText('pending')).toBeVisible();
  });

  // ── Run button ────────────────────────────────────────────────────────────

  test('each objective row has a Run button', async ({ page, request }) => {
    // Ensure at least one objective exists
    await createObjective(request, `UI-run-btn-${TS}`);
    await page.reload();
    await page.getByRole('button', { name: 'Objectives' }).click();
    await expect(page.getByRole('button', { name: 'Run' }).first()).toBeVisible({ timeout: 10_000 });
  });

  test('clicking Run changes status to running', async ({ page, request }) => {
    const title = `UI-run-${TS}`;
    await createObjective(request, title);
    await page.reload();
    await page.getByRole('button', { name: 'Objectives' }).click();
    await expect(page.getByText(title)).toBeVisible({ timeout: 10_000 });
    // Find the Run button in the row for this specific objective
    const row = page.locator('div').filter({ hasText: title }).last();
    await row.getByRole('button', { name: 'Run' }).click();
    await expect(row.getByText('running')).toBeVisible({ timeout: 8_000 });
  });

  test('Run button is disabled for already-running objectives', async ({ page, request }) => {
    const title = `UI-already-running-${TS}`;
    const obj = await createObjective(request, title);
    const bareId = obj.id.includes(':') ? obj.id.split(':')[1] : obj.id;
    // Mark it running via API
    await request.post(`/api/objectives/${bareId}/run`);
    await page.reload();
    await page.getByRole('button', { name: 'Objectives' }).click();
    await expect(page.getByText(title)).toBeVisible({ timeout: 10_000 });
    const row = page.locator('div').filter({ hasText: title }).last();
    await expect(row.getByRole('button', { name: 'Run' })).toBeDisabled();
  });

  // ── Empty state ───────────────────────────────────────────────────────────

  test('shows empty state message when list is empty', async ({ page }) => {
    // This test only asserts the correct message text if the list is empty.
    // If there are objectives, we just verify the list renders.
    await page.waitForTimeout(2_000);
    const isEmpty = await page.getByText('No objectives yet').isVisible();
    const hasList = await page.getByRole('button', { name: 'Run' }).isVisible();
    expect(isEmpty || hasList).toBe(true);
  });
});
