import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { type Character, charactersSchema } from '../schemas/character';

export interface UseCharactersResult {
  characters: Character[];
  isLoading: boolean;
  error: string | null;
}

/**
 * Fetches the full character roster from GET /api/v1/characters.
 * The Axios instance (`api`) automatically attaches the JWT Bearer token
 * via the interceptor wired up by AuthProvider.
 */
export function useCharacters(): UseCharactersResult {
  const [characters, setCharacters] = useState<Character[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchAll() {
      setIsLoading(true);
      setError(null);

      try {
        // Fetch up to 100 characters (seed data has 25).
        const response = await api.get<unknown>('/api/v1/characters', {
          params: { per_page: 100 },
        });
        const parsed = charactersSchema.parse(response.data);
        if (!cancelled) {
          setCharacters(parsed);
        }
      } catch (err: unknown) {
        if (!cancelled) {
          const message = err instanceof Error ? err.message : 'Failed to load characters';
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
  }, []);

  return { characters, isLoading, error };
}
