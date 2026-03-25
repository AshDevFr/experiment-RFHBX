import { z } from 'zod';

export const EVENT_TYPES = ['started', 'progress', 'completed', 'failed', 'restarted', 'artifact_found'] as const;
export type EventType = (typeof EVENT_TYPES)[number];

export const questEventSchema = z.object({
  id: z.number(),
  quest_id: z.number(),
  quest_title: z.string(),
  event_type: z.enum(EVENT_TYPES),
  message: z.string().nullable().optional(),
  data: z.record(z.unknown()).optional(),
  created_at: z.string(),
});

export type QuestEvent = z.infer<typeof questEventSchema>;

export const eventsMetaSchema = z.object({
  total: z.number(),
  page: z.number(),
  per_page: z.number(),
  total_pages: z.number(),
});

export type EventsMeta = z.infer<typeof eventsMetaSchema>;

export const eventsResponseSchema = z.object({
  events: z.array(questEventSchema),
  meta: eventsMetaSchema,
});

export type EventsResponse = z.infer<typeof eventsResponseSchema>;

// ---------------------------------------------------------------------------
// Display helpers
// ---------------------------------------------------------------------------

export const EVENT_TYPE_COLORS: Record<EventType, string> = {
  started: 'blue',
  progress: 'gray',
  completed: 'green',
  failed: 'red',
  restarted: 'orange',
  artifact_found: 'yellow',
};

export const EVENT_TYPE_LABELS: Record<EventType, string> = {
  started: 'Started',
  progress: 'Progress',
  completed: 'Completed',
  failed: 'Failed',
  restarted: 'Restarted',
  artifact_found: 'Artifact Found',
};
