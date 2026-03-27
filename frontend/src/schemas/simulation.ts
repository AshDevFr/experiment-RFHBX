import { z } from 'zod';

export const simulationConfigSchema = z.object({
  id: z.number(),
  mode: z.enum(['campaign', 'random']),
  running: z.boolean(),
  progress_min: z.union([z.string(), z.number()]).transform((v) => Number(v)),
  progress_max: z.union([z.string(), z.number()]).transform((v) => Number(v)),
  campaign_position: z.number(),
  tick_count: z.number().optional().default(0),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
});

export type SimulationConfig = z.infer<typeof simulationConfigSchema>;

export interface SimulationConfigUpdate {
  progress_min?: number;
  progress_max?: number;
  mode?: 'campaign' | 'random';
}
