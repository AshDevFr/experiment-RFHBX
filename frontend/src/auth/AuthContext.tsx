import { User, UserManager, WebStorageStateStore } from 'oidc-client-ts';
import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from 'react';
import { clearAuthTokenAccessor, setAuthTokenAccessor } from '../lib/api';

// ---------------------------------------------------------------------------
// OIDC configuration — all values come from Vite env vars so they can be
// overridden per environment without rebuilding.
// ---------------------------------------------------------------------------
const OIDC_AUTHORITY = import.meta.env.VITE_OIDC_AUTHORITY ?? '';
const OIDC_CLIENT_ID = import.meta.env.VITE_OIDC_CLIENT_ID ?? '';
const OIDC_REDIRECT_URI =
  import.meta.env.VITE_OIDC_REDIRECT_URI ?? `${window.location.origin}/auth/callback`;

// ---------------------------------------------------------------------------
// AuthContext public API
// ---------------------------------------------------------------------------
export interface AuthContextValue {
  /** The current OIDC user (null while loading or unauthenticated). */
  user: User | null;
  /** True once the initial silent-signin / session-restore has completed. */
  isLoading: boolean;
  /** True when a valid, non-expired user is present. */
  isAuthenticated: boolean;
  /** Redirect to the OIDC provider login page (PKCE). */
  login: (returnTo?: string) => Promise<void>;
  /** End the OIDC session and clear in-memory state. */
  logout: () => Promise<void>;
  /** Return the raw access token string, or null if not authenticated. */
  getAccessToken: () => string | null;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// ---------------------------------------------------------------------------
// AuthProvider
// ---------------------------------------------------------------------------

/**
 * Wraps the application tree and manages the full OIDC token lifecycle:
 * - PKCE redirect flow
 * - In-memory token storage (never localStorage)
 * - Silent token renewal before expiry
 * - Exposes login/logout helpers and user info via context
 */
export function AuthProvider({ children }: { children: ReactNode }) {
  const managerRef = useRef<UserManager | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Lazily initialise the UserManager once.
  if (!managerRef.current && OIDC_AUTHORITY && OIDC_CLIENT_ID) {
    managerRef.current = new UserManager({
      authority: OIDC_AUTHORITY,
      client_id: OIDC_CLIENT_ID,
      redirect_uri: OIDC_REDIRECT_URI,
      response_type: 'code',
      scope: 'openid profile email',
      // Store OIDC metadata (not tokens) in sessionStorage so the state
      // survives the redirect round-trip but is cleared when the tab closes.
      // Access tokens are held only in the UserManager's in-memory store.
      stateStore: new WebStorageStateStore({ store: window.sessionStorage }),
      userStore: new WebStorageStateStore({ store: window.sessionStorage }),
      automaticSilentRenew: true,
      // Use an iframe for silent renewal when supported by the provider.
      silent_redirect_uri: `${window.location.origin}/auth/silent-callback`,
    });
  }

  const manager = managerRef.current;

  // Wire up event listeners.
  useEffect(() => {
    if (!manager) {
      setIsLoading(false);
      return;
    }

    const onUserLoaded = (u: User) => setUser(u);
    const onUserUnloaded = () => setUser(null);
    const onSilentRenewError = () => setUser(null);
    const onAccessTokenExpired = () => setUser(null);

    manager.events.addUserLoaded(onUserLoaded);
    manager.events.addUserUnloaded(onUserUnloaded);
    manager.events.addSilentRenewError(onSilentRenewError);
    manager.events.addAccessTokenExpired(onAccessTokenExpired);

    // Attempt to restore an existing session from the state store.
    manager
      .getUser()
      .then((existingUser) => {
        if (existingUser && !existingUser.expired) {
          setUser(existingUser);
        }
      })
      .catch(() => {
        // No valid session — that is fine; user will be prompted to login.
      })
      .finally(() => setIsLoading(false));

    return () => {
      manager.events.removeUserLoaded(onUserLoaded);
      manager.events.removeUserUnloaded(onUserUnloaded);
      manager.events.removeSilentRenewError(onSilentRenewError);
      manager.events.removeAccessTokenExpired(onAccessTokenExpired);
    };
  }, [manager]);

  // Keep the Axios interceptor accessor in sync with the current user.
  useEffect(() => {
    if (user && !user.expired) {
      setAuthTokenAccessor(() => user.access_token);
    } else {
      clearAuthTokenAccessor();
    }
  }, [user]);

  const login = useCallback(
    async (returnTo?: string) => {
      if (!manager) return;
      await manager.signinRedirect({
        // Stash the intended route so the callback can restore it.
        state: returnTo ?? window.location.pathname + window.location.search,
      });
    },
    [manager],
  );

  const logout = useCallback(async () => {
    if (!manager) return;
    setUser(null);
    clearAuthTokenAccessor();
    await manager.signoutRedirect();
  }, [manager]);

  const getAccessToken = useCallback((): string | null => {
    return user?.access_token ?? null;
  }, [user]);

  const isAuthenticated = !!user && !user.expired;

  const value: AuthContextValue = {
    user,
    isLoading,
    isAuthenticated,
    login,
    logout,
    getAccessToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// ---------------------------------------------------------------------------
// useAuth hook
// ---------------------------------------------------------------------------

/** Consume the AuthContext. Must be called inside <AuthProvider>. */
export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used inside <AuthProvider>');
  }
  return ctx;
}
