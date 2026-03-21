import { describe, expect, it } from 'vitest';
import { questSchema, questsSchema } from './quest';

const validQuest = {
  id: 1,
  title: 'Destroy the Ring',
  description: 'Journey to Mount Doom and destroy the One Ring.',
  status: 'pending',
  danger_level: 10,
  region: 'Mordor',
  progress: null,
  success_chance: 15,
  quest_type: 'campaign',
  campaign_order: 1,
  attempts: 0,
};

describe('questSchema', () => {
  it('parses a valid quest', () => {
    const result = questSchema.parse(validQuest);
    expect(result.title).toBe('Destroy the Ring');
    expect(result.status).toBe('pending');
    expect(result.danger_level).toBe(10);
  });

  it('rejects an invalid status', () => {
    expect(() =>
      questSchema.parse({ ...validQuest, status: 'unknown' }),
    ).toThrow();
  });

  it('rejects an invalid quest_type', () => {
    expect(() =>
      questSchema.parse({ ...validQuest, quest_type: 'daily' }),
    ).toThrow();
  });

  it('accepts optional nullable fields as null', () => {
    const result = questSchema.parse({
      ...validQuest,
      description: null,
      region: null,
      progress: null,
      success_chance: null,
      campaign_order: null,
    });
    expect(result.description).toBeNull();
    expect(result.region).toBeNull();
  });

  it('accepts quest with members', () => {
    const result = questSchema.parse({
      ...validQuest,
      members: [
        { id: 1, name: 'Frodo', race: 'Hobbit', level: 3, status: 'idle' },
      ],
    });
    expect(result.members).toHaveLength(1);
    expect(result.members?.[0].name).toBe('Frodo');
  });

  it('parses quest without optional fields', () => {
    const minimal = {
      id: 2,
      title: 'Quick Patrol',
      status: 'active',
      danger_level: 1,
      quest_type: 'random',
      attempts: 0,
    };
    const result = questSchema.parse(minimal);
    expect(result.title).toBe('Quick Patrol');
    expect(result.description).toBeUndefined();
  });
});

describe('questsSchema', () => {
  it('parses an array of quests', () => {
    const result = questsSchema.parse([validQuest, { ...validQuest, id: 2, title: 'Second' }]);
    expect(result).toHaveLength(2);
  });

  it('parses an empty array', () => {
    const result = questsSchema.parse([]);
    expect(result).toHaveLength(0);
  });
});
