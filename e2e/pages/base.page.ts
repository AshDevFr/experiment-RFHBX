import type { Page } from '@playwright/test';

/**
 * Base page object providing shared helpers for all page objects.
 */
export class BasePage {
  constructor(protected readonly page: Page) {}

  /** Navigate to a path relative to baseURL. */
  async goto(path: string): Promise<void> {
    await this.page.goto(path);
  }

  /** Return the current page title. */
  async title(): Promise<string> {
    return this.page.title();
  }

  /** Wait for the page to reach the 'networkidle' state. */
  async waitForNetworkIdle(): Promise<void> {
    await this.page.waitForLoadState('networkidle');
  }
}
