import { cleanup, renderHook, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { api } from '../lib/api';
import { useArtifacts } from './useArtifacts';

vi.mock('../lib/api', () => ({
  api: {
    get: vi.fn(),
  },
}));

const mockGet = vi.mocked(api.get);

const sampleArtifacts = [
  {
    id: 1,
    name: 'Sting',
    artifact_type: 'sword',
    character_id: 42,
    stat_bonus: { strength: 3 },
  },
  {
    id: 2,
    name: 'Mithril Shirt',
    artifact_type: 'armour',
    character_id: 42,
    stat_bonus: { endurance: 5 },
  },
];

describe('useArtifacts', () => {
  afterEach(() => {
    cleanup();
    vi.clearAllMocks();
  });

  it('returns empty artifacts and does not fetch when characterId is undefined', () => {
    const { result } = renderHook(() => useArtifacts(undefined));
    expect(result.current.artifacts).toEqual([]);
    expect(result.current.isLoading).toBe(false);
    expect(mockGet).not.toHaveBeenCalled();
  });

  it('fetches artifacts filtered by character_id', async () => {
    mockGet.mockResolvedValueOnce({ data: sampleArtifacts });

    const { result } = renderHook(() => useArtifacts(42));

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(mockGet).toHaveBeenCalledWith('/api/v1/artifacts', {
      params: { character_id: 42, per_page: 100 },
    });
    expect(result.current.artifacts).toHaveLength(2);
    expect(result.current.artifacts[0].name).toBe('Sting');
    expect(result.current.error).toBeNull();
  });

  it('sets error on fetch failure', async () => {
    mockGet.mockRejectedValueOnce(new Error('Network error'));

    const { result } = renderHook(() => useArtifacts(42));

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.error).toBe('Network error');
    expect(result.current.artifacts).toEqual([]);
  });

  it('sets isLoading true while fetching', () => {
    let resolvePromise: (value: unknown) => void = () => {};
    const promise = new Promise((r) => {
      resolvePromise = r;
    });
    mockGet.mockReturnValueOnce(promise as ReturnType<typeof api.get>);

    const { result } = renderHook(() => useArtifacts(42));

    expect(result.current.isLoading).toBe(true);
    resolvePromise({ data: [] });
  });

  it('refetches when characterId changes', async () => {
    mockGet.mockResolvedValue({ data: [] });

    const { rerender } = renderHook(({ id }: { id: number }) => useArtifacts(id), {
      initialProps: { id: 1 },
    });

    await waitFor(() => expect(mockGet).toHaveBeenCalledTimes(1));

    rerender({ id: 2 });

    await waitFor(() => expect(mockGet).toHaveBeenCalledTimes(2));
    expect(mockGet).toHaveBeenLastCalledWith('/api/v1/artifacts', {
      params: { character_id: 2, per_page: 100 },
    });
  });
});
