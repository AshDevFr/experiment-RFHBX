import axios from 'axios';

export const api = axios.create({
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
  timeout: 10_000,
});

// ---------------------------------------------------------------------------
// Authorization interceptor
// ---------------------------------------------------------------------------
// Token accessor is set by AuthProvider once the OIDC library is initialised.
// Keeping it as a module-level setter avoids a circular dependency between
// AuthContext and this module.
let _getAccessToken: (() => string | null) | null = null;

/**
 * Register the token accessor from AuthProvider so the interceptor can
 * attach the Bearer token to every outbound request.
 *
 * Called once from AuthProvider during initialisation.
 */
export function setAuthTokenAccessor(fn: () => string | null): void {
  _getAccessToken = fn;
}

/**
 * Clear the token accessor (e.g. on logout).
 */
export function clearAuthTokenAccessor(): void {
  _getAccessToken = null;
}

api.interceptors.request.use((config) => {
  if (_getAccessToken) {
    const token = _getAccessToken();
    if (token) {
      config.headers = config.headers ?? {};
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});
