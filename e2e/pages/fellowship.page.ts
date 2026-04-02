import type { Locator, Page } from '@playwright/test';
import { BasePage } from './base.page';

/**
 * Page object for the /fellowship (characters list) route.
 */
export class FellowshipPage extends BasePage {
  /** Table rows inside the fellowship/characters table body. */
  readonly characterRows: Locator;
  /** The page heading. */
  readonly heading: Locator;

  constructor(page: Page) {
    super(page);
    // Characters are rendered in a table or as card/list items.
    // Try table rows first, fall back to any repeated data item.
    this.characterRows = page.locator('table tbody tr, [data-testid="character-row"]');
    this.heading = page.locator('h1, h2').first();
  }

  /** Navigate to the fellowship (characters) page. */
  async navigate(): Promise<void> {
    await this.goto('/fellowship');
  }

  /** Return the number of character rows visible on the page. */
  async characterCount(): Promise<number> {
    // Wait for at least one row to appear (seeded data)
    await this.characterRows.first().waitFor({ state: 'visible', timeout: 30_000 });
    return this.characterRows.count();
  }
}
