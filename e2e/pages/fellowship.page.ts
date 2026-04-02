import type { Locator, Page } from '@playwright/test';
import { BasePage } from './base.page';

/**
 * Page object for the /fellowship (characters list) route.
 */
export class FellowshipPage extends BasePage {
  /** Character cards rendered by the fellowship page. */
  readonly characterRows: Locator;
  /** The page heading. */
  readonly heading: Locator;

  constructor(page: Page) {
    super(page);
    // Characters are rendered as Mantine Card components with
    // data-testid="character-card".  Also accept legacy table rows so that
    // a future table-based redesign doesn't silently break these tests.
    this.characterRows = page.locator('table tbody tr, [data-testid="character-card"]');
    this.heading = page.locator('h1, h2').first();
  }

  /** Navigate to the fellowship (characters) page. */
  async navigate(): Promise<void> {
    await this.goto('/fellowship');
  }

  /** Return the number of character rows visible on the page. */
  async characterCount(): Promise<number> {
    // Wait for at least one card to appear (seeded data)
    await this.characterRows.first().waitFor({ state: 'visible', timeout: 30_000 });
    return this.characterRows.count();
  }
}
