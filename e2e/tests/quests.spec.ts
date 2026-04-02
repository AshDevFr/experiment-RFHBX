import { test, expect } from '../fixtures/auth.fixture';
import { QuestsPage } from '../pages/quests.page';

test.describe('Quests List', () => {
  test('renders at least one quest row', async ({ authedPage }) => {
    const questsPage = new QuestsPage(authedPage);
    await questsPage.navigate();

    // The heading should be visible
    await expect(questsPage.heading).toBeVisible({ timeout: 15_000 });

    // At least one quest should be rendered from seed data
    const count = await questsPage.questCount();
    expect(count).toBeGreaterThanOrEqual(1);
  });
});
