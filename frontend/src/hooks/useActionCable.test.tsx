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
});
