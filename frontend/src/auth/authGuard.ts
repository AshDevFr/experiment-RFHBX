import type { ParsedLocation } from '@tanstack/react-router';
import type { AuthContextValue } from './AuthContext';

/**
 * TanStack Router `beforeLoad` guard for protected routes.
 *
 * Usage:
 * ```ts
 * export const Route = createFileRoute('/protected')(
 *   createProtectedRoute({
 *     component: ProtectedPage,
 *   }),
 * );
 * ```
 *
 * Or inline:
 * ```ts
 * export const Route = createFileRoute('/protected')({
 *   beforeLoad: ({ context, location }) =>
 *     requireAuth(context.auth, location),
 *   component: ProtectedPage,
 * });
 * ```
 */
export function requireAuth(
  auth: AuthContextValue | undefined,
  location: ParsedLocation,
): void {
  if (!auth) {
    // Auth context is not yet wired — bail out silently; the router will
    // re-run beforeLoad once the context is available.
    return;
  }

  if (!auth.isLoading && !auth.isAuthenticated) {
    // Redirect to OIDC login, preserving the current path as the return-to
    // destination so the callback can restore it after sign-in.
    auth.login(location.pathname + location.search);
    // Throw a redirect-like object recognised by TanStack Router to abort
    // the current navigation without rendering the protected component.
    throw Object.assign(new Error('Unauthenticated'), { isRedirect: true });
  }
}
