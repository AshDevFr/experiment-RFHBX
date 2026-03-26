import { act, cleanup, renderHook } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ActionCableProvider } from './useActionCable';
import { useQuestEventsChannel } from './useQuestEventsChannel';

// ---------------------------------------------------------------------------
// Mock @rails/actioncable
// ---------------------------------------------------------------------------
let capturedCallbacks: Record<string, (...args: unknown[]) => void> = {};
const mockUnsubscribe = vi.fn();
const mockCreate = vi.fn((_params, callbacks) => {
  capturedCallbacks = callbacks;
  return { unsubscribe: mockUnsubscribe };
});
const mockDisconnect = vi.fn();
const mockConsumer = {
  disconnect: mockDisconnect,
  subscriptions: { create: mockCreate },
};

vi.mock('@rails/actioncable', () => ({
  createConsumer: vi.fn(() => mockConsumer),
}));

// Mock useAuth so ActionCableProvider can render without a real AuthProvider.
vi.mock('../auth/AuthProvider', () => ({
  useAuth: () => ({ getAccessToken: () => null }),
}));

function wrapper({ children }: { children: ReactNode }) {
  return <ActionCableProvider>{children}</ActionCableProvider>;
}

describe('useQuestEventsChannel', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    capturedCallbacks = {};
  });

  afterEach(() => {
    cleanup();
  });

  it('subscribes to QuestEventsChannel on mount', () => {
    renderHook(() => useQuestEventsChannel(), { wrapper });
    expect(mockCreate).toHaveBeenCalledOnce();
    expect(mockCreate).toHaveBeenCalledWith(
      { channel: 'QuestEventsChannel' },
      expect.objectContaining({ connected: expect.any(Function), received: expect.any(Function) }),
    );
  });

  it('subscribes with quest_id when provided', () => {
    renderHook(() => useQuestEventsChannel(42), { wrapper });
    expect(mockCreate).toHaveBeenCalledWith(
      { channel: 'QuestEventsChannel', quest_id: 42 },
      expect.any(Object),
    );
  });

  it('starts in connecting status and transitions to connected', () => {
    const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
    expect(result.current.connectionStatus).toBe('connecting');
    act(() => capturedCallbacks.connected?.());
    expect(result.current.connectionStatus).toBe('connected');
  });

  it('exposes the latest received event', () => {
    const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
    expect(result.current.latestEvent).toBeNull();

    const event = { type: 'quest_started', quest_id: 1 };
    act(() => capturedCallbacks.received?.(event));
    expect(result.current.latestEvent).toEqual(event);
  });

  it('sets status to disconnected when disconnected callback fires', () => {
    const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
    act(() => capturedCallbacks.disconnected?.());
    expect(result.current.connectionStatus).toBe('disconnected');
  });

  it('unsubscribes on unmount', () => {
    const { unmount } = renderHook(() => useQuestEventsChannel(), { wrapper });
    unmount();
    expect(mockUnsubscribe).toHaveBeenCalledOnce();
  });

  // ---------------------------------------------------------------------------
  // Out-of-order progress-event ordering tests
  // ---------------------------------------------------------------------------
  describe('progress event ordering (stale-broadcast guard)', () => {
    it('accepts the first progress event regardless of timestamp', () => {
      const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
      const event = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.3 },
        occurred_at: '2026-01-01T00:00:01.000Z',
      };
      act(() => capturedCallbacks.received?.(event));
      expect(result.current.latestEvent).toEqual(event);
    });

    it('accepts a newer progress event (later timestamp advances latestEvent)', () => {
      const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
      const first = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.3 },
        occurred_at: '2026-01-01T00:00:01.000Z',
      };
      const second = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.5 },
        occurred_at: '2026-01-01T00:00:02.000Z',
      };
      act(() => capturedCallbacks.received?.(first));
      act(() => capturedCallbacks.received?.(second));
      expect(result.current.latestEvent).toEqual(second);
    });

    it('discards a stale progress event (older timestamp) to prevent backward flicker', () => {
      const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
      const newer = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.7 },
        occurred_at: '2026-01-01T00:00:05.000Z',
      };
      const stale = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.2 },
        occurred_at: '2026-01-01T00:00:02.000Z',
      };
      act(() => capturedCallbacks.received?.(newer));
      act(() => capturedCallbacks.received?.(stale));
      // stale event must be ignored; latestEvent stays as the newer one
      expect(result.current.latestEvent).toEqual(newer);
    });

    it('discards a duplicate progress event with the same timestamp', () => {
      const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
      const first = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.4 },
        occurred_at: '2026-01-01T00:00:03.000Z',
      };
      const dup = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.4 },
        occurred_at: '2026-01-01T00:00:03.000Z',
      };
      act(() => capturedCallbacks.received?.(first));
      act(() => capturedCallbacks.received?.(dup));
      expect(result.current.latestEvent).toEqual(first);
    });

    it('always passes through status-transition events regardless of timestamp', () => {
      const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
      // Establish a progress timestamp
      const progress = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.9 },
        occurred_at: '2026-01-01T00:00:10.000Z',
      };
      act(() => capturedCallbacks.received?.(progress));

      // A completed event with an earlier timestamp must still be accepted
      const completed = {
        event_type: 'completed',
        quest_id: 1,
        data: { xp_awarded: 500 },
        occurred_at: '2026-01-01T00:00:01.000Z',
      };
      act(() => capturedCallbacks.received?.(completed));
      expect(result.current.latestEvent).toEqual(completed);
    });

    it('always passes through a restarted event regardless of timestamp', () => {
      const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
      const progress = {
        event_type: 'progress',
        quest_id: 2,
        data: { progress: 0.5 },
        occurred_at: '2026-01-01T00:00:08.000Z',
      };
      act(() => capturedCallbacks.received?.(progress));

      const restarted = {
        event_type: 'restarted',
        quest_id: 2,
        data: { attempt: 2 },
        occurred_at: '2026-01-01T00:00:01.000Z',
      };
      act(() => capturedCallbacks.received?.(restarted));
      expect(result.current.latestEvent).toEqual(restarted);
    });

    it('accepts progress events without occurred_at (backward compatibility)', () => {
      const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
      const withoutTs = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.6 },
        // no occurred_at
      };
      act(() => capturedCallbacks.received?.(withoutTs));
      expect(result.current.latestEvent).toEqual(withoutTs);
    });

    it('resets timestamp tracking when subscription is recreated (questId change)', () => {
      // Start with questId=1
      const { result, rerender } = renderHook(
        ({ qId }: { qId: number | undefined }) => useQuestEventsChannel(qId),
        { wrapper, initialProps: { qId: 1 } },
      );

      // Establish a high timestamp for quest 1
      const q1Event = {
        event_type: 'progress',
        quest_id: 1,
        data: { progress: 0.9 },
        occurred_at: '2026-01-01T00:01:00.000Z',
      };
      act(() => capturedCallbacks.received?.(q1Event));
      expect(result.current.latestEvent).toEqual(q1Event);

      // Switch to questId=2 — subscription recreates, timestamp tracking resets
      act(() => rerender({ qId: 2 }));

      // An early-timestamp progress event for quest 2 must now be accepted
      const q2Event = {
        event_type: 'progress',
        quest_id: 2,
        data: { progress: 0.1 },
        occurred_at: '2026-01-01T00:00:01.000Z',
      };
      act(() => capturedCallbacks.received?.(q2Event));
      expect(result.current.latestEvent).toEqual(q2Event);
    });
  });
});
