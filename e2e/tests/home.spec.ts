import { expect, test } from '@playwright/test';

test.describe('Home Page', () => {
  test('renders without JS errors', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // The page should have loaded (either the login page or a redirect).
    // Verify no uncaught JS exceptions occurred during render.
    expect(errors).toHaveLength(0);

    // The page should have a non-empty title or visible content
    const body = page.locator('body');
    await expect(body).not.toBeEmpty();
  });

  test('page has visible content', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // The app should render something — either the login form or a redirect
    const heading = page.locator('h1, h2, h3, h4').first();
    await expect(heading).toBeVisible({ timeout: 15_000 });
  });
});
