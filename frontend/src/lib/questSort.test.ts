import { describe, expect, it } from 'vitest';
import type { Quest } from '../schemas/quest';
import { sortQuests } from './questSort';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function makeQuest(overrides: Partial<Quest> & { id: number; title: string }): Quest {
  return {
    status: 'pending',
    danger_level: 1,
    quest_type: 'campaign',
    campaign_order: null,
    attempts: 0,
    progress: null,
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
describe('sortQuests', () => {
  it('returns an empty array unchanged', () => {
    expect(sortQuests([])).toEqual([]);
  });

  it('places active quests before pending quests', () => {
    const quests = [
      makeQuest({ id: 1, title: 'Pending', status: 'pending', campaign_order: 1 }),
      makeQuest({ id: 2, title: 'Active', status: 'active', campaign_order: 2 }),
    ];

    const sorted = sortQuests(quests);
    expect(sorted[0].status).toBe('active');
    expect(sorted[1].status).toBe('pending');
  });

  it('places completed quests after all other quests', () => {
    const quests = [
      makeQuest({ id: 1, title: 'Completed', status: 'completed', campaign_order: 1 }),
      makeQuest({ id: 2, title: 'Pending', status: 'pending', campaign_order: 2 }),
      makeQuest({ id: 3, title: 'Active', status: 'active', campaign_order: 3 }),
    ];

    const sorted = sortQuests(quests);
    expect(sorted[0].status).toBe('active');
    expect(sorted[1].status).toBe('pending');
    expect(sorted[2].status).toBe('completed');
  });

  it('sorts non-active, non-completed quests by campaign_order ascending', () => {
    const quests = [
      makeQuest({ id: 1, title: 'Third', status: 'pending', campaign_order: 3 }),
      makeQuest({ id: 2, title: 'First', status: 'failed', campaign_order: 1 }),
      makeQuest({ id: 3, title: 'Second', status: 'pending', campaign_order: 2 }),
    ];

    const sorted = sortQuests(quests);
    expect(sorted.map((q) => q.campaign_order)).toEqual([1, 2, 3]);
  });

  it('places quests without campaign_order after those that have one (within same priority group)', () => {
    const quests = [
      makeQuest({ id: 1, title: 'No Order', status: 'pending', campaign_order: null }),
      makeQuest({ id: 2, title: 'Has Order', status: 'pending', campaign_order: 1 }),
    ];

    const sorted = sortQuests(quests);
    expect(sorted[0].title).toBe('Has Order');
    expect(sorted[1].title).toBe('No Order');
  });

  it('handles the full priority order: active → others by campaign_order → completed', () => {
    const quests = [
      makeQuest({ id: 1, title: 'Completed Quest', status: 'completed', campaign_order: 1 }),
      makeQuest({ id: 2, title: 'Active Quest', status: 'active', campaign_order: 2 }),
      makeQuest({ id: 3, title: 'Pending Quest B', status: 'pending', campaign_order: 4 }),
      makeQuest({ id: 4, title: 'Failed Quest', status: 'failed', campaign_order: 3 }),
      makeQuest({ id: 5, title: 'Pending Quest A', status: 'pending', campaign_order: 2 }),
    ];

    const sorted = sortQuests(quests);

    expect(sorted[0].title).toBe('Active Quest');
    expect(sorted[1].title).toBe('Pending Quest A');
    expect(sorted[2].title).toBe('Failed Quest');
    expect(sorted[3].title).toBe('Pending Quest B');
    expect(sorted[4].title).toBe('Completed Quest');
  });

  it('does not mutate the original array', () => {
    const quests = [
      makeQuest({ id: 1, title: 'Completed', status: 'completed', campaign_order: 1 }),
      makeQuest({ id: 2, title: 'Active', status: 'active', campaign_order: 2 }),
    ];
    const original = [...quests];

    sortQuests(quests);

    expect(quests).toEqual(original);
  });

  it('handles multiple active quests, ordering them by campaign_order among themselves', () => {
    const quests = [
      makeQuest({ id: 1, title: 'Active B', status: 'active', campaign_order: 2 }),
      makeQuest({ id: 2, title: 'Active A', status: 'active', campaign_order: 1 }),
    ];

    const sorted = sortQuests(quests);
    expect(sorted[0].title).toBe('Active A');
    expect(sorted[1].title).toBe('Active B');
  });

  it('handles multiple completed quests, ordering them by campaign_order among themselves', () => {
    const quests = [
      makeQuest({ id: 1, title: 'Completed B', status: 'completed', campaign_order: 2 }),
      makeQuest({ id: 2, title: 'Completed A', status: 'completed', campaign_order: 1 }),
    ];

    const sorted = sortQuests(quests);
    expect(sorted[0].title).toBe('Completed A');
    expect(sorted[1].title).toBe('Completed B');
  });

  it('handles quests with mixed quest_types (campaign and random)', () => {
    const quests = [
      makeQuest({
        id: 1,
        title: 'Random Active',
        status: 'active',
        quest_type: 'random',
        campaign_order: null,
      }),
      makeQuest({
        id: 2,
        title: 'Campaign Pending',
        status: 'pending',
        quest_type: 'campaign',
        campaign_order: 1,
      }),
      makeQuest({
        id: 3,
        title: 'Random Pending',
        status: 'pending',
        quest_type: 'random',
        campaign_order: null,
      }),
      makeQuest({
        id: 4,
        title: 'Campaign Completed',
        status: 'completed',
        quest_type: 'campaign',
        campaign_order: 2,
      }),
    ];

    const sorted = sortQuests(quests);

    // Active first
    expect(sorted[0].title).toBe('Random Active');
    // Campaign quests with order before random quests without order
    expect(sorted[1].title).toBe('Campaign Pending');
    expect(sorted[2].title).toBe('Random Pending');
    // Completed last
    expect(sorted[3].title).toBe('Campaign Completed');
  });
});
