import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthContextValue } from '../auth/AuthContext';

// ---------------------------------------------------------------------------
// Mock useAuth so we can control the auth context in each test.
// ---------------------------------------------------------------------------
const mockUseAuth = vi.fn<() => Partial<AuthContextValue>>();

vi.mock('../auth/AuthContext', () => ({
  useAuth: () => mockUseAuth(),
}));

import { UserInfo } from './UserInfo';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

describe('UserInfo', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('shows a loading indicator while auth is resolving', () => {
    mockUseAuth.mockReturnValue({ isLoading: true, isAuthenticated: false, user: null });
    render(<UserInfo />, { wrapper });
    expect(screen.getByText('\u2026')).toBeInTheDocument();
  });

  it('shows a sign-in button when unauthenticated', () => {
    mockUseAuth.mockReturnValue({
      isLoading: false,
      isAuthenticated: false,
      user: null,
      login: vi.fn(),
    });
    render(<UserInfo />, { wrapper });
    expect(screen.getByText('Sign in')).toBeInTheDocument();
  });

  it('renders the user display name when authenticated', () => {
    mockUseAuth.mockReturnValue({
      isLoading: false,
      isAuthenticated: true,
      user: {
        access_token: 'tok',
        expired: false,
        profile: { sub: 'u1', name: 'Frodo Baggins', email: 'frodo@shire.me' },
      } as AuthContextValue['user'],
      login: vi.fn(),
      logout: vi.fn(),
    });

    render(<UserInfo />, { wrapper });
    expect(screen.getByText('Frodo Baggins')).toBeInTheDocument();
  });

  it('falls back to email when name is absent', () => {
    mockUseAuth.mockReturnValue({
      isLoading: false,
      isAuthenticated: true,
      user: {
        access_token: 'tok',
        expired: false,
        profile: { sub: 'u2', email: 'sam@shire.me' },
      } as AuthContextValue['user'],
      login: vi.fn(),
      logout: vi.fn(),
    });

    render(<UserInfo />, { wrapper });
    expect(screen.getByText('sam@shire.me')).toBeInTheDocument();
  });

  it('falls back to sub when name and email are absent', () => {
    mockUseAuth.mockReturnValue({
      isLoading: false,
      isAuthenticated: true,
      user: {
        access_token: 'tok',
        expired: false,
        profile: { sub: 'user-xyz' },
      } as AuthContextValue['user'],
      login: vi.fn(),
      logout: vi.fn(),
    });

    render(<UserInfo />, { wrapper });
    expect(screen.getByText('user-xyz')).toBeInTheDocument();
  });
});
