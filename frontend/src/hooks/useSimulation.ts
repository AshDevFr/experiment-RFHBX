import { useCallback, useEffect, useReducer, useRef, useState } from 'react';
import { api } from '../lib/api';
import {
  type SimulationConfig,
  type SimulationConfigUpdate,
  simulationConfigSchema,
} from '../schemas/simulation';

const POLL_INTERVAL_MS = 10_000;

export interface UseSimulationResult {
  config: SimulationConfig | null;
  isLoading: boolean;
  error: string | null;
  isActing: boolean;
  start: () => Promise<void>;
  stop: () => Promise<void>;
  updateConfig: (update: SimulationConfigUpdate) => Promise<void>;
  refetch: () => void;
}

async function fetchStatus(): Promise<SimulationConfig> {
  const response = await api.get<unknown>('/api/v1/simulation/status');
  return simulationConfigSchema.parse(response.data);
}

export function useSimulation(): UseSimulationResult {
  const [config, setConfig] = useState<SimulationConfig | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isActing, setIsActing] = useState(false);
  const [tick, bump] = useReducer((n: number) => n + 1, 0);

  const refetch = useCallback(() => {
    bump();
  }, []);

  // biome-ignore lint/correctness/useExhaustiveDependencies: tick is an intentional refetch trigger
  useEffect(() => {
    let cancelled = false;

    async function load() {
      setIsLoading(true);
      setError(null);
      try {
        const data = await fetchStatus();
        if (!cancelled) setConfig(data);
      } catch (err: unknown) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Failed to load simulation status');
        }
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [tick]);

  // Auto-refresh every 10 seconds
  const tickRef = useRef(tick);
  tickRef.current = tick;
  useEffect(() => {
    const id = setInterval(() => {
      bump();
    }, POLL_INTERVAL_MS);
    return () => clearInterval(id);
  }, []);

  const start = useCallback(async () => {
    setIsActing(true);
    setError(null);
    try {
      const response = await api.post<unknown>('/api/v1/simulation/start');
      setConfig(simulationConfigSchema.parse(response.data));
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to start simulation');
    } finally {
      setIsActing(false);
    }
  }, []);

  const stop = useCallback(async () => {
    setIsActing(true);
    setError(null);
    try {
      const response = await api.post<unknown>('/api/v1/simulation/stop');
      setConfig(simulationConfigSchema.parse(response.data));
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to stop simulation');
    } finally {
      setIsActing(false);
    }
  }, []);

  const updateConfig = useCallback(async (update: SimulationConfigUpdate) => {
    setIsActing(true);
    setError(null);
    try {
      const response = await api.patch<unknown>('/api/v1/simulation/config', update);
      setConfig(simulationConfigSchema.parse(response.data));
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to update simulation config');
    } finally {
      setIsActing(false);
    }
  }, []);

  return { config, isLoading, error, isActing, start, stop, updateConfig, refetch };
}
