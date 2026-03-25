import { z } from 'zod';

export const characterSchema = z.object({
  id: z.number(),
  name: z.string(),
  race: z.string(),
  realm: z.string().nullable().optional(),
  title: z.string().nullable().optional(),
  ring_bearer: z.boolean().optional(),
  level: z.number().optional(),
  xp: z.number().optional(),
  strength: z.number().optional(),
  wisdom: z.number().optional(),
  endurance: z.number().optional(),
  status: z.string().optional(),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
  artifact_count: z.number().optional(),
});

export type Character = z.infer<typeof characterSchema>;

export const charactersSchema = z.array(characterSchema);
