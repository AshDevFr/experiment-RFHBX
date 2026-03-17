import { z } from 'zod';

export const healthSchema = z.object({
  status: z.string(),
  version: z.string(),
  environment: z.string(),
});

export type Health = z.infer<typeof healthSchema>;
