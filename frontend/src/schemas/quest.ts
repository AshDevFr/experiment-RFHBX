import { z } from 'zod';

export const questMemberSchema = z.object({
  id: z.number(),
  name: z.string(),
  race: z.string(),
  level: z.number().nullable().optional(),
  status: z.string().nullable().optional(),
});

export type QuestMember = z.infer<typeof questMemberSchema>;

export const questSchema = z.object({
  id: z.number(),
  title: z.string(),
  description: z.string().nullable().optional(),
  status: z.enum(['pending', 'active', 'completed', 'failed']),
  danger_level: z.number(),
  region: z.string().nullable().optional(),
  progress: z.number().nullable().optional(),
  success_chance: z.number().nullable().optional(),
  quest_type: z.enum(['campaign', 'random']),
  campaign_order: z.number().nullable().optional(),
  attempts: z.number(),
  members: z.array(questMemberSchema).optional(),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
});

export type Quest = z.infer<typeof questSchema>;

export const questsSchema = z.array(questSchema);

export const QUEST_STATUS_TRANSITIONS: Record<Quest['status'], Quest['status'] | null> = {
  pending: 'active',
  active: 'completed',
  completed: null,
  failed: null,
};

export const QUEST_STATUS_LABELS: Record<Quest['status'], string> = {
  pending: 'Pending',
  active: 'Active',
  completed: 'Completed',
  failed: 'Failed',
};

export const QUEST_STATUS_COLORS: Record<Quest['status'], string> = {
  pending: 'gray',
  active: 'blue',
  completed: 'green',
  failed: 'red',
};
