import { act, cleanup, renderHook } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ActionCableProvider } from './useActionCable';
import { useSauronGazeChannel } from './useSauronGazeChannel';

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

describe('useSauronGazeChannel', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    capturedCallbacks = {};
  });

  afterEach(() => {
    cleanup();
  });

  it('subscribes to SauronGazeChannel on mount', () => {
    renderHook(() => useSauronGazeChannel(), { wrapper });
    expect(mockCreate).toHaveBeenCalledOnce();
    expect(mockCreate).toHaveBeenCalledWith(
      { channel: 'SauronGazeChannel' },
      expect.objectContaining({ connected: expect.any(Function), received: expect.any(Function) }),
    );
  });

  it('starts in connecting status and transitions to connected', () => {
    const { result } = renderHook(() => useSauronGazeChannel(), { wrapper });
    expect(result.current.connectionStatus).toBe('connecting');
    act(() => capturedCallbacks.connected?.());
    expect(result.current.connectionStatus).toBe('connected');
  });

  it('exposes the latest received gaze payload', () => {
    const { result } = renderHook(() => useSauronGazeChannel(), { wrapper });
    expect(result.current.latestGaze).toBeNull();

    const gaze = { intensity: 0.8, target: 'fellowship' };
    act(() => capturedCallbacks.received?.(gaze));
    expect(result.current.latestGaze).toEqual(gaze);
  });

  it('sets status to disconnected when disconnected callback fires', () => {
    const { result } = renderHook(() => useSauronGazeChannel(), { wrapper });
    act(() => capturedCallbacks.disconnected?.());
    expect(result.current.connectionStatus).toBe('disconnected');
  });

  it('unsubscribes on unmount', () => {
    const { unmount } = renderHook(() => useSauronGazeChannel(), { wrapper });
    unmount();
    expect(mockUnsubscribe).toHaveBeenCalledOnce();
  });
});
