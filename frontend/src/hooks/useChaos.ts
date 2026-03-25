import { useCallback, useState } from 'react';
import { api } from '../lib/api';
import {
  type ChaosActionResult,
  type ChaosFailQuestResult,
  type ChaosSpikeResult,
  type ChaosStopSimulationResult,
  type ChaosWoundCharacterResult,
  chaosFailQuestResultSchema,
  chaosSpikeResultSchema,
  chaosStopSimulationResultSchema,
  chaosWoundCharacterResultSchema,
} from '../schemas/chaos';

export interface UseChaosResult {
  result: ChaosActionResult | null;
  error: string | null;
  isLoading: boolean;
  woundCharacter: () => Promise<boolean>;
  failQuest: () => Promise<boolean>;
  spikeThreat: () => Promise<boolean>;
  stopSimulation: () => Promise<boolean>;
  clearResult: () => void;
}

export function useChaos(): UseChaosResult {
  const [result, setResult] = useState<ChaosActionResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const clearResult = useCallback(() => {
    setResult(null);
    setError(null);
  }, []);

  const woundCharacter = useCallback(async (): Promise<boolean> => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await api.post<unknown>('/api/v1/chaos/wound_character');
      const parsed: ChaosWoundCharacterResult = chaosWoundCharacterResultSchema.parse(
        response.data,
      );
      setResult({ type: 'wound_character', result: parsed });
      return true;
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to wound character');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const failQuest = useCallback(async (): Promise<boolean> => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await api.post<unknown>('/api/v1/chaos/fail_quest');
      const parsed: ChaosFailQuestResult = chaosFailQuestResultSchema.parse(response.data);
      setResult({ type: 'fail_quest', result: parsed });
      return true;
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to fail quest');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const spikeThreat = useCallback(async (): Promise<boolean> => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await api.post<unknown>('/api/v1/chaos/spike_threat');
      const parsed: ChaosSpikeResult = chaosSpikeResultSchema.parse(response.data);
      setResult({ type: 'spike_threat', result: parsed });
      return true;
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to spike threat level');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const stopSimulation = useCallback(async (): Promise<boolean> => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await api.post<unknown>('/api/v1/chaos/stop_simulation');
      const parsed: ChaosStopSimulationResult = chaosStopSimulationResultSchema.parse(
        response.data,
      );
      setResult({ type: 'stop_simulation', result: parsed });
      return true;
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to stop simulation');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  return {
    result,
    error,
    isLoading,
    woundCharacter,
    failQuest,
    spikeThreat,
    stopSimulation,
    clearResult,
  };
}
