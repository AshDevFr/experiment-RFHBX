import { z } from 'zod';

// ---------------------------------------------------------------------------
// Individual chaos response schemas
// ---------------------------------------------------------------------------

export const chaosWoundCharacterResultSchema = z.object({
  affected: z.object({
    id: z.number(),
    name: z.string(),
    status: z.string(),
    quest_id: z.number().nullable(),
  }),
});
export type ChaosWoundCharacterResult = z.infer<typeof chaosWoundCharacterResultSchema>;

export const chaosFailQuestResultSchema = z.object({
  affected: z.object({
    id: z.number(),
    title: z.string(),
    status: z.string(),
    progress: z.number(),
    members_reset: z.number(),
  }),
});
export type ChaosFailQuestResult = z.infer<typeof chaosFailQuestResultSchema>;

export const chaosSpikeResultSchema = z.object({
  affected: z.object({
    region: z.string(),
    threat_level: z.number(),
    quest_id: z.number(),
  }),
});
export type ChaosSpikeResult = z.infer<typeof chaosSpikeResultSchema>;

export const chaosStopSimulationResultSchema = z.object({
  affected: z.object({
    simulation_running: z.boolean(),
    message: z.string(),
  }),
});
export type ChaosStopSimulationResult = z.infer<typeof chaosStopSimulationResultSchema>;

// ---------------------------------------------------------------------------
// Discriminated union for all chaos results
// ---------------------------------------------------------------------------

export type ChaosActionResult =
  | { type: 'wound_character'; result: ChaosWoundCharacterResult }
  | { type: 'fail_quest'; result: ChaosFailQuestResult }
  | { type: 'spike_threat'; result: ChaosSpikeResult }
  | { type: 'stop_simulation'; result: ChaosStopSimulationResult };
