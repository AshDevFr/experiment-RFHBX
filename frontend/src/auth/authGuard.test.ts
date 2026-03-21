import { redirect } from '@tanstack/react-router';
import { describe, expect, it, vi } from 'vitest';
import type { AuthContextValue } from './AuthContext';
import { requireAuth } from './authGuard';

// Mock TanStack Router redirect so we can assert it's thrown.
vi.mock('@tanstack/react-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@tanstack/react-router')>();
  return {
    ...actual,
    redirect: vi.fn((opts) => {
      // Return an object that mimics a thrown redirect in tests.
      const err = new Error('Redirect');
      Object.assign(err, { isRedirect: true, ...opts });
      return err;
    }),
  };
});

function makeAuth(overrides: Partial<AuthContextValue> = {}): AuthContextValue {
  return {
    user: null,
    isLoading: false,
    isAuthenticated: false,
    login: vi.fn(),
    logout: vi.fn(),
    getAccessToken: vi.fn(),
    ...overrides,
  };
}

function makeLocation(pathname = '/quests', search = '') {
  return { pathname, search, href: pathname + search } as Parameters<typeof requireAuth>[1];
}

describe('requireAuth', () => {
  it('does nothing when auth context is undefined', () => {
    expect(() => requireAuth(undefined, makeLocation())).not.toThrow();
  });

  it('does nothing while auth is still loading', () => {
    const auth = makeAuth({ isLoading: true, isAuthenticated: false });
    expect(() => requireAuth(auth, makeLocation())).not.toThrow();
  });

  it('does nothing when the user is authenticated', () => {
    const auth = makeAuth({ isLoading: false, isAuthenticated: true });
    expect(() => requireAuth(auth, makeLocation())).not.toThrow();
  });

  it('throws a redirect to /login when unauthenticated', () => {
    const auth = makeAuth({ isLoading: false, isAuthenticated: false });
    const location = makeLocation('/quests');

    expect(() => requireAuth(auth, location)).toThrow();
    expect(redirect).toHaveBeenCalledWith(
      expect.objectContaining({
        to: '/login',
        search: { returnTo: '/quests' },
      }),
    );
  });

  it('preserves search params in returnTo when redirecting', () => {
    const auth = makeAuth({ isLoading: false, isAuthenticated: false });
    const location = makeLocation('/fellowship', '?filter=active');

    expect(() => requireAuth(auth, location)).toThrow();
    expect(redirect).toHaveBeenCalledWith(
      expect.objectContaining({
        to: '/login',
        search: { returnTo: '/fellowship?filter=active' },
      }),
    );
  });
});
