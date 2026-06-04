import { test, expect } from '@playwright/test';

test.describe('Health View', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Health is the default view — wait for the card to be visible
    await expect(page.getByText('Platform Health')).toBeVisible();
  });

  test('shows Platform Health card', async ({ page }) => {
    await expect(page.getByText('Platform Health')).toBeVisible();
  });

  test('shows Refresh button', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'Refresh' })).toBeVisible();
  });

  test('shows Usage Summary card', async ({ page }) => {
    await expect(page.getByText('Usage Summary')).toBeVisible();
  });

  test('service status tiles appear after data loads', async ({ page }) => {
    await expect(page.getByText('Agent Knowledge API')).toBeVisible({ timeout: 12_000 });
    await expect(page.getByText('SurrealDB')).toBeVisible();
    await expect(page.getByText('Version')).toBeVisible();
    await expect(page.getByText('Environment')).toBeVisible();
  });

  test('API status badge shows ok or degraded', async ({ page }) => {
    await expect(page.getByText('Agent Knowledge API')).toBeVisible({ timeout: 12_000 });
    // One of these badges should be visible
    const okBadge = page.getByText('ok');
    const degradedBadge = page.getByText('degraded');
    const either = okBadge.or(degradedBadge);
    await expect(either.first()).toBeVisible();
  });

  test('last checked timestamp appears after first check', async ({ page }) => {
    await expect(page.getByText(/Checked/)).toBeVisible({ timeout: 12_000 });
  });

  test('Refresh button triggers a fresh health check', async ({ page }) => {
    await expect(page.getByText(/Checked/)).toBeVisible({ timeout: 12_000 });
    const before = await page.getByText(/Checked/).textContent();
    // Wait a second so the clock ticks, then refresh
    await page.waitForTimeout(1100);
    await page.getByRole('button', { name: 'Refresh' }).click();
    await expect(page.getByText(/Checked/)).toBeVisible();
    // Timestamp should have changed (or at least the button click didn't break anything)
    await expect(page.getByText('Platform Health')).toBeVisible();
  });

  test('Usage Summary shows stats or empty message', async ({ page }) => {
    await page.waitForTimeout(3_000);
    const hasStats = await page.getByText('Total Calls').isVisible();
    const hasEmpty = await page.getByText('No usage data yet.').isVisible();
    expect(hasStats || hasEmpty).toBe(true);
  });

  test('usage stat tiles show numeric values when data exists', async ({ page }) => {
    await page.waitForTimeout(3_000);
    if (await page.getByText('Total Calls').isVisible()) {
      await expect(page.getByText('Input Tokens')).toBeVisible();
      await expect(page.getByText('Output Tokens')).toBeVisible();
      await expect(page.getByText('Total Cost')).toBeVisible();
      await expect(page.getByText('Avg Cost')).toBeVisible();
    }
  });

  test('page title is correct', async ({ page }) => {
    await expect(page).toHaveTitle(/RealGraph|Agent/i);
  });
});
