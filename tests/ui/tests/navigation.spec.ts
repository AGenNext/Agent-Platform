import { test, expect } from '@playwright/test';

test.describe('Navigation & Layout', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('shows RealGraph branding in sidebar', async ({ page }) => {
    await expect(page.getByText('RealGraph')).toBeVisible();
    await expect(page.getByText('Agent Platform')).toBeVisible();
  });

  test('sidebar has all four nav items', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'Health' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Objectives' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Artifacts' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'A2A Trace' })).toBeVisible();
  });

  test('Health is the default active view', async ({ page }) => {
    // Header shows the active view name
    await expect(page.locator('header').getByText('Health')).toBeVisible();
    await expect(page.getByText('Platform Health')).toBeVisible();
  });

  test('clicking Objectives navigates to Objectives view', async ({ page }) => {
    await page.getByRole('button', { name: 'Objectives' }).click();
    await expect(page.locator('header').getByText('Objectives')).toBeVisible();
    await expect(page.getByRole('button', { name: 'New Objective' })).toBeVisible();
  });

  test('clicking Artifacts navigates to Artifacts view', async ({ page }) => {
    await page.getByRole('button', { name: 'Artifacts' }).click();
    await expect(page.locator('header').getByText('Artifacts')).toBeVisible();
    await expect(page.getByText('Artifacts')).toBeVisible();
  });

  test('clicking A2A Trace navigates to trace view', async ({ page }) => {
    await page.getByRole('button', { name: 'A2A Trace' }).click();
    await expect(page.locator('header').getByText('A2A Trace')).toBeVisible();
    await expect(page.getByText('A2A Trace Explorer')).toBeVisible();
  });

  test('navigating back to Health restores health view', async ({ page }) => {
    await page.getByRole('button', { name: 'Objectives' }).click();
    await page.getByRole('button', { name: 'Health' }).click();
    await expect(page.getByText('Platform Health')).toBeVisible();
  });

  test('API Docs link points to /api/docs', async ({ page }) => {
    const link = page.getByRole('link', { name: 'API Docs →' });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute('href', '/api/docs');
    await expect(link).toHaveAttribute('target', '_blank');
  });

  test('active nav item has highlighted style', async ({ page }) => {
    const healthBtn = page.getByRole('button', { name: 'Health' });
    // Active item has indigo background styling
    await expect(healthBtn).toHaveClass(/indigo/);
  });

  test('inactive nav items have muted style', async ({ page }) => {
    const objectivesBtn = page.getByRole('button', { name: 'Objectives' });
    await expect(objectivesBtn).toHaveClass(/slate/);
  });
});
