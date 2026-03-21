import { cleanup, renderHook, waitFor } from '@testing-library/react';
import axios from 'axios';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useQuests } from './useQuests';

// Mock the api module so we don't make real HTTP requests.
vi.mock('../lib/api', () => ({
  api: {
    get: vi.fn(),
  },
}));

import { api } from '../lib/api';

const mockApiGet = vi.mocked(api.get);

const sampleQuests = [
  {
    id: 1,
    title: 'Destroy the Ring',
    description: 'Journey to Mount Doom and destroy the One Ring.',
    status: 'pending',
    danger_level: 10,
    region: 'Mordor',
    progress: null,
    success_chance: 15,
    quest_type: 'campaign',
    campaign_order: 1,
    attempts: 0,
  },
  {
    id: 2,
    title: 'Scout the Shire',
    description: 'Patrol the borders of the Shire.',
    status: 'active',
    danger_level: 2,
    region: 'The Shire',
    progress: 45,
    success_chance: 90,
    quest_type: 'random',
    campaign_order: null,
    attempts: 1,
  },
];

describe('useQuests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('returns quests from the API on success', async () => {
    mockApiGet.mockResolvedValueOnce({ data: sampleQuests });

    const { result } = renderHook(() => useQuests());

    // Initially loading.
    expect(result.current.isLoading).toBe(true);
    expect(result.current.quests).toEqual([]);
    expect(result.current.error).toBeNull();

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.quests).toHaveLength(2);
    expect(result.current.quests[0].title).toBe('Destroy the Ring');
    expect(result.current.quests[1].title).toBe('Scout the Shire');
    expect(result.current.error).toBeNull();
  });

  it('sets error when the API call fails', async () => {
    mockApiGet.mockRejectedValueOnce(new Error('Network Error'));

    const { result } = renderHook(() => useQuests());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.quests).toEqual([]);
    expect(result.current.error).toBe('Network Error');
  });

  it('calls the correct endpoint with per_page param', async () => {
    mockApiGet.mockResolvedValueOnce({ data: [] });

    renderHook(() => useQuests());

    await waitFor(() => {
      expect(mockApiGet).toHaveBeenCalledWith('/api/v1/quests', {
        params: { per_page: 100 },
      });
    });
  });

  it('handles Axios errors with a descriptive message', async () => {
    const axiosError = new axios.AxiosError('Request failed with status code 401');
    mockApiGet.mockRejectedValueOnce(axiosError);

    const { result } = renderHook(() => useQuests());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.error).toContain('401');
  });
});
