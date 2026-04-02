import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for Mordor's Edge E2E smoke tests.
 *
 * BASE_URL: The frontend URL (default: http://localhost:5173).
 * API_BASE_URL: The backend URL (default: http://localhost:3000).
 *
 * When running inside Docker Compose the service names resolve via DNS,
 * so these are overridden to http://frontend:5173 and http://backend:3000.
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: process.env.CI
    ? [['html', { open: 'never', outputFolder: 'playwright-report' }], ['list']]
    : [['html', { open: 'on-failure' }], ['list']],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  /* No webServer — the stack is managed by Docker Compose. */
});
