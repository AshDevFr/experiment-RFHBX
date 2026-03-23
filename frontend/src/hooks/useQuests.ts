import { useCallback, useEffect, useReducer, useState } from 'react';
import { api } from '../lib/api';
import { type Quest, questsSchema } from '../schemas/quest';

export interface UseQuestsResult {
  quests: Quest[];
  isLoading: boolean;
  error: string | null;
  refetch: () => void;
}

/**
 * Fetches the quest roster from GET /api/v1/quests.
 * The Axios instance (`api`) automatically attaches the JWT Bearer token
 * via the interceptor wired up by AuthProvider.
 */
export function useQuests(): UseQuestsResult {
  const [quests, setQuests] = useState<Quest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tick, bump] = useReducer((n: number) => n + 1, 0);

  const refetch = useCallback(() => {
    bump();
  }, []);

  // biome-ignore lint/correctness/useExhaustiveDependencies: tick is an intentional trigger for re-fetching
  useEffect(() => {
    let cancelled = false;

    async function fetchAll() {
      setIsLoading(true);
      setError(null);

      try {
        const response = await api.get<unknown>('/api/v1/quests', {
          params: { per_page: 100 },
        });
        const parsed = questsSchema.parse(response.data);
        if (!cancelled) {
          setQuests(parsed);
        }
      } catch (err: unknown) {
        if (!cancelled) {
          const message = err instanceof Error ? err.message : 'Failed to load quests';
          setError(message);
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    fetchAll();

    return () => {
      cancelled = true;
    };
  }, [tick]);

  return { quests, isLoading, error, refetch };
}
