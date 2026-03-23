import { MantineProvider } from '@mantine/core';
import { cleanup, render } from '@testing-library/react';
import type { ReactElement } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// ---------------------------------------------------------------------------
// Mutable location state — updated per test before render.
// Named with "mock" prefix so Vitest hoists them with vi.mock factories.
// ---------------------------------------------------------------------------
const mockNavigate = vi.fn();
let mockLocation = {
  pathname: '/quests',
  searchStr: '',
  search: {} as Record<string, unknown>,
};
let mockAuthState = { isLoading: false, isAuthenticated: false };

vi.mock('@tanstack/react-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@tanstack/react-router')>();
  return {
    ...actual,
    // createFileRoute returns a function that returns the options object so
    // we can access Route.component in tests.
    createFileRoute: () => (opts: unknown) => opts,
    Outlet: (): null => null,
    useNavigate: () => mockNavigate,
    useRouterState: ({ select }: { select: (s: { location: unknown }) => unknown }) =>
      select({ location: mockLocation }),
  };
});

vi.mock('../auth/AuthProvider', () => ({
  useAuth: () => mockAuthState,
}));

vi.mock('../auth/authGuard', () => ({
  requireAuth: vi.fn(),
}));

// Import AFTER vi.mock calls so the mocks are in place.
import { Route } from './_auth';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const AuthenticatedLayout = (Route as any).component as () => ReactElement | null;

describe('AuthenticatedLayout — returnTo redirect', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockAuthState = { isLoading: false, isAuthenticated: false };
  });

  afterEach(() => {
    cleanup();
  });

  it('builds a plain pathname returnTo when there are no query params', () => {
    mockLocation = { pathname: '/quests', searchStr: '', search: {} };

    render(
      <MantineProvider>
        <AuthenticatedLayout />
      </MantineProvider>,
    );

    expect(mockNavigate).toHaveBeenCalledWith(
      expect.objectContaining({
        to: '/login',
        search: { returnTo: '/quests' },
      }),
    );

    const { returnTo } = mockNavigate.mock.calls[0][0].search as { returnTo: string };
    expect(typeof returnTo).toBe('string');
    expect(returnTo).not.toContain('[object');
  });

  it('appends raw query string to returnTo when query params are present', () => {
    mockLocation = {
      pathname: '/fellowship',
      searchStr: '?ring=one&bearer=frodo',
      search: { ring: 'one', bearer: 'frodo' },
    };

    render(
      <MantineProvider>
        <AuthenticatedLayout />
      </MantineProvider>,
    );

    expect(mockNavigate).toHaveBeenCalledWith(
      expect.objectContaining({
        to: '/login',
        search: { returnTo: '/fellowship?ring=one&bearer=frodo' },
      }),
    );
  });

  it('returnTo is always a string, never serialised as [object Object]', () => {
    // Simulate what the old buggy code would have done: location.search is an object.
    mockLocation = {
      pathname: '/dashboard',
      searchStr: '?tab=active',
      search: { tab: 'active' },
    };

    render(
      <MantineProvider>
        <AuthenticatedLayout />
      </MantineProvider>,
    );

    const call = mockNavigate.mock.calls[0]?.[0] as { search: { returnTo: string } };
    expect(call).toBeDefined();
    expect(typeof call.search.returnTo).toBe('string');
    expect(call.search.returnTo).toBe('/dashboard?tab=active');
    expect(call.search.returnTo).not.toMatch(/\[object/);
  });

  it('does NOT call navigate when already authenticated', () => {
    mockAuthState = { isLoading: false, isAuthenticated: true };
    mockLocation = { pathname: '/quests', searchStr: '', search: {} };

    render(
      <MantineProvider>
        <AuthenticatedLayout />
      </MantineProvider>,
    );

    expect(mockNavigate).not.toHaveBeenCalled();
  });

  it('does NOT call navigate while auth is still loading', () => {
    mockAuthState = { isLoading: true, isAuthenticated: false };
    mockLocation = { pathname: '/quests', searchStr: '', search: {} };

    render(
      <MantineProvider>
        <AuthenticatedLayout />
      </MantineProvider>,
    );

    expect(mockNavigate).not.toHaveBeenCalled();
  });
});
