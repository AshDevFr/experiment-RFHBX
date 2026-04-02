import { expect, test } from '@playwright/test';
import { HomePage } from '../pages/home.page';

test.describe('Home Page', () => {
  test('renders without JS errors', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));

    const homePage = new HomePage(page);
    await homePage.navigate();
    await homePage.waitForNetworkIdle();

    // The page should have loaded (either the login page or a redirect).
    // Verify no uncaught JS exceptions occurred during render.
    expect(errors).toHaveLength(0);

    // The page should have a non-empty title or visible content
    const body = page.locator('body');
    await expect(body).not.toBeEmpty();
  });

  test('page has visible content', async ({ page }) => {
    const homePage = new HomePage(page);
    await homePage.navigate();

    // The app should render something — either the login form or a redirect
    await expect(homePage.heading).toBeVisible({ timeout: 15_000 });
  });
});
