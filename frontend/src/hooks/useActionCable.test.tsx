import { cleanup, renderHook } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ActionCableProvider, useActionCable } from './useActionCable';

// ---------------------------------------------------------------------------
// Mock @rails/actioncable
// vi.hoisted ensures these variables are available inside the vi.mock factory,
// which is hoisted to the top of the file by Vitest.
// ---------------------------------------------------------------------------
const { mockDisconnect, mockConsumer, mockCreateConsumer } = vi.hoisted(() => {
  const mockDisconnect = vi.fn();
  const mockConsumer = { disconnect: mockDisconnect, subscriptions: { create: vi.fn() } };
  const mockCreateConsumer = vi.fn(() => mockConsumer);
  return { mockDisconnect, mockConsumer, mockCreateConsumer };
});

vi.mock('@rails/actioncable', () => ({
  createConsumer: mockCreateConsumer,
}));

function wrapper({ children }: { children: ReactNode }) {
  return <ActionCableProvider>{children}</ActionCableProvider>;
}

describe('ActionCableProvider / useActionCable', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('creates a consumer with the cable URL on mount', () => {
    renderHook(() => useActionCable(), { wrapper });
    expect(mockCreateConsumer).toHaveBeenCalledOnce();
    expect(mockCreateConsumer).toHaveBeenCalledWith('ws://localhost:3000/cable');
  });

  it('returns the consumer instance from the hook', () => {
    const { result } = renderHook(() => useActionCable(), { wrapper });
    expect(result.current).toBe(mockConsumer);
  });

  it('disconnects the consumer on unmount', () => {
    const { unmount } = renderHook(() => useActionCable(), { wrapper });
    unmount();
    expect(mockDisconnect).toHaveBeenCalledOnce();
  });

  it('reuses the same consumer within a single provider', () => {
    // Two hooks rendered inside the same provider tree share the same consumer.
    const { result } = renderHook(() => ({ a: useActionCable(), b: useActionCable() }), {
      wrapper,
    });
    expect(result.current.a).toBe(mockConsumer);
    expect(result.current.b).toBe(mockConsumer);
    expect(mockCreateConsumer).toHaveBeenCalledOnce();
  });

  it('throws when used outside ActionCableProvider', () => {
    expect(() => {
      renderHook(() => useActionCable());
    }).toThrow('useActionCable must be used inside <ActionCableProvider>');
  });

  it('creates exactly one consumer on mount (no duplicates during initialisation)', () => {
    renderHook(() => useActionCable(), { wrapper });
    // Even though the guard runs in the render body, createConsumer must only
    // ever be called once per mount cycle.
    expect(mockCreateConsumer).toHaveBeenCalledTimes(1);
  });

  it('after unmount the consumer is disconnected; remount creates a new consumer (StrictMode-safe)', () => {
    // First mount
    const { unmount } = renderHook(() => useActionCable(), { wrapper });
    expect(mockCreateConsumer).toHaveBeenCalledTimes(1);

    // Unmount — simulates StrictMode cleanup or a genuine provider teardown.
    unmount();
    expect(mockDisconnect).toHaveBeenCalledTimes(1);

    // Second mount — the ref was cleared on unmount so a fresh consumer must
    // be created, not the stale disconnected one.
    vi.clearAllMocks();
    renderHook(() => useActionCable(), { wrapper });
    expect(mockCreateConsumer).toHaveBeenCalledTimes(1);
    // The previous consumer is already disconnected; the new one is not yet.
    expect(mockDisconnect).not.toHaveBeenCalled();
  });

  it('never has two live consumers at the same time (no concurrent duplicates)', () => {
    // Mount → disconnect (simulates StrictMode cleanup) → remount.
    // At no point should there be two un-disconnected consumers alive.
    const { unmount: unmount1 } = renderHook(() => useActionCable(), { wrapper });
    expect(mockCreateConsumer).toHaveBeenCalledTimes(1);
    expect(mockDisconnect).toHaveBeenCalledTimes(0);

    // Simulate the StrictMode simulated unmount of the first effect.
    unmount1();
    expect(mockDisconnect).toHaveBeenCalledTimes(1);

    // Remount: only one new consumer is created — not two.
    vi.clearAllMocks();
    const { unmount: unmount2 } = renderHook(() => useActionCable(), { wrapper });
    expect(mockCreateConsumer).toHaveBeenCalledTimes(1);
    expect(mockDisconnect).toHaveBeenCalledTimes(0); // new consumer still live

    unmount2();
    expect(mockDisconnect).toHaveBeenCalledTimes(1);
  });
});
