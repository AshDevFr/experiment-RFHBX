import { test, expect } from '../fixtures/auth.fixture';
import { FellowshipPage } from '../pages/fellowship.page';

test.describe('Characters List (Fellowship)', () => {
  test('renders at least one character row', async ({ authedPage }) => {
    const fellowshipPage = new FellowshipPage(authedPage);
    await fellowshipPage.navigate();

    // The heading should be visible
    await expect(fellowshipPage.heading).toBeVisible({ timeout: 15_000 });

    // At least one character should be rendered from seed data
    const count = await fellowshipPage.characterCount();
    expect(count).toBeGreaterThanOrEqual(1);
  });
});
