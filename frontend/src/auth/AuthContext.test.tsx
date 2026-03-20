import { cleanup, render, renderHook, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { ReactNode } from 'react';

// ---------------------------------------------------------------------------
// Mock oidc-client-ts so tests never hit a real OIDC server.
// ---------------------------------------------------------------------------
const mockGetUser = vi.fn();
const mockSigninRedirect = vi.fn();
const mockSignoutRedirect = vi.fn();
const mockEvents = {
  addUserLoaded: vi.fn(),
  addUserUnloaded: vi.fn(),
  addSilentRenewError: vi.fn(),
  addAccessTokenExpired: vi.fn(),
  removeUserLoaded: vi.fn(),
  removeUserUnloaded: vi.fn(),
  removeSilentRenewError: vi.fn(),
  removeAccessTokenExpired: vi.fn(),
};

vi.mock('oidc-client-ts', () => ({
  UserManager: vi.fn().mockImplementation(() => ({
    getUser: mockGetUser,
    signinRedirect: mockSigninRedirect,
    signoutRedirect: mockSignoutRedirect,
    events: mockEvents,
  })),
  WebStorageStateStore: vi.fn().mockImplementation(() => ({})),
  User: class {},
}));

// Provide dummy env vars so the UserManager constructor path is exercised.
vi.stubEnv('VITE_OIDC_AUTHORITY', 'https://auth.example.com');
vi.stubEnv('VITE_OIDC_CLIENT_ID', 'test-client');
vi.stubEnv('VITE_OIDC_REDIRECT_URI', 'http://localhost:5173/auth/callback');

import { AuthProvider, useAuth } from './AuthContext';

function wrapper({ children }: { children: ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>;
}

describe('AuthProvider', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('starts in loading state then resolves to unauthenticated when no session', async () => {
    mockGetUser.mockResolvedValueOnce(null);

    const { result } = renderHook(() => useAuth(), { wrapper });

    // Initially loading.
    expect(result.current.isLoading).toBe(true);

    await waitFor(() => expect(result.current.isLoading).toBe(false));
    expect(result.current.isAuthenticated).toBe(false);
    expect(result.current.user).toBeNull();
  });

  it('becomes authenticated when UserManager returns a valid user', async () => {
    const fakeUser = {
      access_token: 'test-access-token',
      expired: false,
      profile: { sub: 'user-123', name: 'Frodo Baggins', email: 'frodo@shire.me' },
    };
    mockGetUser.mockResolvedValueOnce(fakeUser);

    const { result } = renderHook(() => useAuth(), { wrapper });

    await waitFor(() => expect(result.current.isLoading).toBe(false));
    expect(result.current.isAuthenticated).toBe(true);
    expect(result.current.user).toEqual(fakeUser);
    expect(result.current.getAccessToken()).toBe('test-access-token');
  });

  it('renders children regardless of auth state', async () => {
    mockGetUser.mockResolvedValueOnce(null);

    render(
      <AuthProvider>
        <span data-testid="child">hello</span>
      </AuthProvider>,
    );

    expect(screen.getByTestId('child')).toBeInTheDocument();
  });

  it('calls signinRedirect when login() is invoked', async () => {
    mockGetUser.mockResolvedValueOnce(null);
    mockSigninRedirect.mockResolvedValueOnce(undefined);

    const { result } = renderHook(() => useAuth(), { wrapper });
    await waitFor(() => expect(result.current.isLoading).toBe(false));

    await result.current.login('/dashboard');

    expect(mockSigninRedirect).toHaveBeenCalledWith(
      expect.objectContaining({ state: '/dashboard' }),
    );
  });

  it('calls signoutRedirect and clears user when logout() is invoked', async () => {
    const fakeUser = {
      access_token: 'tok',
      expired: false,
      profile: { sub: 'u1' },
    };
    mockGetUser.mockResolvedValueOnce(fakeUser);
    mockSignoutRedirect.mockResolvedValueOnce(undefined);

    const { result } = renderHook(() => useAuth(), { wrapper });
    await waitFor(() => expect(result.current.isAuthenticated).toBe(true));

    await result.current.logout();

    expect(mockSignoutRedirect).toHaveBeenCalled();
    // User is cleared synchronously before the redirect.
    expect(result.current.user).toBeNull();
  });

  it('throws when useAuth is used outside <AuthProvider>', () => {
    // Suppress React's console.error for this expected throw.
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => renderHook(() => useAuth())).toThrow(
      'useAuth must be used inside <AuthProvider>',
    );
    spy.mockRestore();
  });
});
