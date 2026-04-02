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
}
