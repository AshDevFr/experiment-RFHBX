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

// Mock useAuth so ActionCableProvider can render without a real AuthProvider.
vi.mock('../auth/AuthProvider', () => ({
  useAuth: () => ({ getAccessToken: () => null }),
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

    const gaze = {
      region: 'Mordor',
      threat_level: 8,
      message: 'The Eye turns toward Mordor',
      watched_at: '2026-03-20T12:00:00Z',
    };
    act(() => capturedCallbacks.received?.(gaze));
    expect(result.current.latestGaze).toEqual(gaze);
  });

  it('sets status to disconnected when disconnected callback fires', () => {
    const { result } = renderHook(() => useSauronGazeChannel(), { wrapper });
    act(() => capturedCallbacks.disconnected?.());
    expect(result.current.connectionStatus).toBe('disconnected');
  });

  it('unsubscribes on unmount after subscription is confirmed', () => {
    const { unmount } = renderHook(() => useSauronGazeChannel(), { wrapper });
    act(() => capturedCallbacks.connected?.());
    unmount();
    expect(mockUnsubscribe).toHaveBeenCalledOnce();
  });

  it('does not call unsubscribe immediately if component unmounts before confirmation (race condition)', () => {
    const { unmount } = renderHook(() => useSauronGazeChannel(), { wrapper });
    // Unmount before connected() fires — must NOT send unsubscribe yet
    unmount();
    expect(mockUnsubscribe).not.toHaveBeenCalled();
  });

  it('issues a deferred unsubscribe when connected() fires after component has unmounted', () => {
    const { unmount } = renderHook(() => useSauronGazeChannel(), { wrapper });
    unmount();
    expect(mockUnsubscribe).not.toHaveBeenCalled();
    // Server confirms subscription after unmount — deferred cleanup fires
    act(() => capturedCallbacks.connected?.());
    expect(mockUnsubscribe).toHaveBeenCalledOnce();
  });

  it('does not throw when unsubscribe fails on unmount (consumer already disconnected)', () => {
    mockUnsubscribe.mockImplementationOnce(() => {
      throw new Error(
        'Unable to find subscription with identifier: {"channel":"SauronGazeChannel"}',
      );
    });
    const { unmount } = renderHook(() => useSauronGazeChannel(), { wrapper });
    act(() => capturedCallbacks.connected?.());
    expect(() => unmount()).not.toThrow();
  });
});
