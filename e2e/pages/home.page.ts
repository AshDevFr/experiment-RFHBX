import type { Locator, Page } from '@playwright/test';
import { BasePage } from './base.page';

/**
 * Page object for the home / index route.
 */
export class HomePage extends BasePage {
  readonly heading: Locator;

  constructor(page: Page) {
    super(page);
    this.heading = page.locator('h1, h2, h3').first();
  }

  /** Navigate to the home page. */
  async navigate(): Promise<void> {
    await this.goto('/');
  }

  /** Check that the page rendered without uncaught JS errors. */
  async hasNoConsoleErrors(): Promise<boolean> {
    const errors: string[] = [];
    this.page.on('pageerror', (err) => errors.push(err.message));
    // Give the page a moment to settle after navigation
    await this.page.waitForTimeout(1_000);
    return errors.length === 0;
  }
}
