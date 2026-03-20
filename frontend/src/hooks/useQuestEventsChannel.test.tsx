import { cleanup, renderHook, act } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { ReactNode } from 'react';
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
    act(() => capturedCallbacks['connected']?.());
    expect(result.current.connectionStatus).toBe('connected');
  });

  it('exposes the latest received event', () => {
    const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
    expect(result.current.latestEvent).toBeNull();

    const event = { type: 'quest_started', quest_id: 1 };
    act(() => capturedCallbacks['received']?.(event));
    expect(result.current.latestEvent).toEqual(event);
  });

  it('sets status to disconnected when disconnected callback fires', () => {
    const { result } = renderHook(() => useQuestEventsChannel(), { wrapper });
    act(() => capturedCallbacks['disconnected']?.());
    expect(result.current.connectionStatus).toBe('disconnected');
  });

  it('unsubscribes on unmount', () => {
    const { unmount } = renderHook(() => useQuestEventsChannel(), { wrapper });
    unmount();
    expect(mockUnsubscribe).toHaveBeenCalledOnce();
  });
});
