import type { ParsedLocation } from '@tanstack/react-router';
import { redirect } from '@tanstack/react-router';
import type { AuthContextValue } from './AuthContext';

/**
 * TanStack Router `beforeLoad` guard for protected routes.
 *
 * Redirects unauthenticated users to `/login`, preserving the original
 * destination in the `returnTo` search parameter so the login page can
 * restore it after sign-in.
 *
 * Usage (in a file-based route):
 * ```ts
 * export const Route = createFileRoute('/protected')({
 *   beforeLoad: ({ context, location }) =>
 *     requireAuth(context.auth, location),
 *   component: ProtectedPage,
 * });
 * ```
 */
export function requireAuth(auth: AuthContextValue | undefined, location: ParsedLocation): void {
  if (!auth) {
    // Auth context is not yet wired — bail out silently; the _auth layout
    // component will handle the redirect once auth resolves.
    return;
  }

  if (!auth.isLoading && !auth.isAuthenticated) {
    throw redirect({
      to: '/login',
      search: { returnTo: location.pathname + location.search },
    });
  }
}
