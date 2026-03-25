import type { Quest } from '../schemas/quest';

/**
 * Return a numeric sort priority for a quest based on its status.
 *
 * 0 → active   (in-progress — most actionable, float to top)
 * 1 → all other statuses (pending, failed) — secondary sort by campaign_order
 * 2 → completed (least actionable — sink to bottom)
 */
function questSortPriority(quest: Quest): number {
  if (quest.status === 'active') return 0;
  if (quest.status === 'completed') return 2;
  return 1;
}

/**
 * Sort a quest list so that:
 * 1. In-progress (active) quests appear first.
 * 2. Completed quests appear last.
 * 3. All other quests (pending, failed, etc.) are ordered by campaign_order
 *    ascending. Quests without a campaign_order (e.g. random quests) are
 *    placed after those that have one, preserving their relative order.
 *
 * The original array is not mutated; a new sorted array is returned.
 */
export function sortQuests(quests: Quest[]): Quest[] {
  return [...quests].sort((a, b) => {
    const pa = questSortPriority(a);
    const pb = questSortPriority(b);

    if (pa !== pb) return pa - pb;

    // Within the same priority group, sort by campaign_order ascending.
    // Quests without a campaign_order receive a large sentinel value so they
    // sort after those that have one (preserving original relative order for
    // ties via a stable sort).
    const ca = a.campaign_order ?? Number.MAX_SAFE_INTEGER;
    const cb = b.campaign_order ?? Number.MAX_SAFE_INTEGER;
    return ca - cb;
  });
}
