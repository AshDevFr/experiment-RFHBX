import { cleanup, renderHook, waitFor } from '@testing-library/react';
import axios from 'axios';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useCharacters } from './useCharacters';

// Mock the api module so we don't make real HTTP requests.
vi.mock('../lib/api', () => ({
  api: {
    get: vi.fn(),
  },
}));

import { api } from '../lib/api';

const mockApiGet = vi.mocked(api.get);

const sampleCharacters = [
  {
    id: 1,
    name: 'Frodo Baggins',
    race: 'Hobbit',
    realm: 'The Shire',
    title: 'Ring Bearer',
    ring_bearer: true,
    status: 'idle',
    strength: 5,
    wisdom: 14,
    endurance: 12,
    level: 1,
    xp: 0,
  },
  {
    id: 2,
    name: 'Aragorn',
    race: 'Human',
    realm: 'Gondor',
    title: 'King Elessar',
    ring_bearer: false,
    status: 'idle',
    strength: 17,
    wisdom: 15,
    endurance: 16,
    level: 1,
    xp: 0,
  },
];

describe('useCharacters', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('returns characters from the API on success', async () => {
    mockApiGet.mockResolvedValueOnce({ data: sampleCharacters });

    const { result } = renderHook(() => useCharacters());

    // Initially loading.
    expect(result.current.isLoading).toBe(true);
    expect(result.current.characters).toEqual([]);
    expect(result.current.error).toBeNull();

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.characters).toHaveLength(2);
    expect(result.current.characters[0].name).toBe('Frodo Baggins');
    expect(result.current.characters[1].name).toBe('Aragorn');
    expect(result.current.error).toBeNull();
  });

  it('sets error when the API call fails', async () => {
    mockApiGet.mockRejectedValueOnce(new Error('Network Error'));

    const { result } = renderHook(() => useCharacters());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.characters).toEqual([]);
    expect(result.current.error).toBe('Network Error');
  });

  it('calls the correct endpoint with per_page param', async () => {
    mockApiGet.mockResolvedValueOnce({ data: [] });

    renderHook(() => useCharacters());

    await waitFor(() => {
      expect(mockApiGet).toHaveBeenCalledWith('/api/v1/characters', {
        params: { per_page: 100 },
      });
    });
  });

  it('handles Axios errors with a descriptive message', async () => {
    const axiosError = new axios.AxiosError('Request failed with status code 401');
    mockApiGet.mockRejectedValueOnce(axiosError);

    const { result } = renderHook(() => useCharacters());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).toContain('401');
  });
});
