import { z } from 'zod';

export const artifactSchema = z.object({
  id: z.number(),
  name: z.string(),
  artifact_type: z.string(),
  power: z.string().nullable().optional(),
  corrupted: z.boolean().optional(),
  character_id: z.number().nullable().optional(),
  stat_bonus: z.record(z.number()).optional().default({}),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
});

export type Artifact = z.infer<typeof artifactSchema>;

export const artifactsSchema = z.array(artifactSchema);
