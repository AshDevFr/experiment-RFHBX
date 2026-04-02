import { test as base, type Page } from '@playwright/test';
import { LoginPage } from '../pages/login.page';

/**
 * Custom Playwright fixture that performs dev-bypass authentication
 * before each test that requires it.
 *
 * Usage:
 *   import { test } from '../fixtures/auth.fixture';
 *   test('my test', async ({ authedPage }) => { ... });
 */
export const test = base.extend<{ authedPage: Page }>({
  authedPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.navigate();
    await loginPage.devLogin();
    // Wait for redirect to complete after dev login
    await page.waitForURL('**/quests**', { timeout: 15_000 });
    await use(page);
  },
});

export { expect } from '@playwright/test';
