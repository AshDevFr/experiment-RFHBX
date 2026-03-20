import { cleanup, renderHook } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { ReactNode } from 'react';
import { ActionCableProvider, useActionCable } from './useActionCable';

// ---------------------------------------------------------------------------
// Mock @rails/actioncable
// ---------------------------------------------------------------------------
const mockDisconnect = vi.fn();
const mockConsumer = { disconnect: mockDisconnect, subscriptions: { create: vi.fn() } };
const mockCreateConsumer = vi.fn(() => mockConsumer);

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

  it('reuses the same consumer across multiple hook calls', () => {
    const { result: r1 } = renderHook(() => useActionCable(), { wrapper });
    const { result: r2 } = renderHook(() => useActionCable(), { wrapper });
    // Both hooks should see the same consumer instance from the same provider.
    expect(r1.current).toBe(mockConsumer);
    expect(r2.current).toBe(mockConsumer);
    expect(mockCreateConsumer).toHaveBeenCalledOnce();
  });

  it('throws when used outside ActionCableProvider', () => {
    expect(() => {
      renderHook(() => useActionCable());
    }).toThrow('useActionCable must be used inside <ActionCableProvider>');
  });
});
