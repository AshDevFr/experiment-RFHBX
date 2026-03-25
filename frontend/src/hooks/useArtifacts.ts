import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { type Artifact, artifactsSchema } from '../schemas/artifact';

export interface UseArtifactsResult {
  artifacts: Artifact[];
  isLoading: boolean;
  error: string | null;
}

/**
 * Fetches artifacts from GET /api/v1/artifacts.
 * When `characterId` is provided the results are filtered to that character.
 */
export function useArtifacts(characterId?: number): UseArtifactsResult {
  const [artifacts, setArtifacts] = useState<Artifact[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (characterId === undefined) {
      setArtifacts([]);
      return;
    }

    let cancelled = false;
    setIsLoading(true);
    setError(null);

    async function fetchArtifacts() {
      try {
        const response = await api.get<unknown>('/api/v1/artifacts', {
          params: { character_id: characterId, per_page: 100 },
        });
        const parsed = artifactsSchema.parse(response.data);
        if (!cancelled) {
          setArtifacts(parsed);
        }
      } catch (err: unknown) {
        if (!cancelled) {
          const message = err instanceof Error ? err.message : 'Failed to load artifacts';
          setError(message);
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    fetchArtifacts();

    return () => {
      cancelled = true;
    };
  }, [characterId]);

  return { artifacts, isLoading, error };
}
