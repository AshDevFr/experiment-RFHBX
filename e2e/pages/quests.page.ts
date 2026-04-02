import type { Locator, Page } from '@playwright/test';
import { BasePage } from './base.page';

/**
 * Page object for the /quests route.
 */
export class QuestsPage extends BasePage {
  /** Rows or cards representing quests. */
  readonly questRows: Locator;
  /** The page heading. */
  readonly heading: Locator;

  constructor(page: Page) {
    super(page);
    // Quests may be rendered as table rows, cards, or list items.
    this.questRows = page.locator(
      'table tbody tr, [data-testid="quest-row"], [data-testid="quest-card"]',
    );
    this.heading = page.locator('h1, h2').first();
  }

  /** Navigate to the quests page. */
  async navigate(): Promise<void> {
    await this.goto('/quests');
  }

  /** Return the number of quest rows/cards visible on the page. */
  async questCount(): Promise<number> {
    // Wait for at least one quest to appear (seeded data)
    await this.questRows.first().waitFor({ state: 'visible', timeout: 30_000 });
    return this.questRows.count();
  }
}
