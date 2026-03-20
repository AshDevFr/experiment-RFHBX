import { createFileRoute } from '@tanstack/react-router';
import { UserManager } from 'oidc-client-ts';
import { useEffect } from 'react';

/**
 * Handles the silent-renewal iframe callback.
 *
 * The UserManager opens this page inside a hidden iframe to obtain a fresh
 * access token via the OIDC provider's session cookie.  It must complete the
 * exchange and then signal the parent frame — `signinSilentCallback()` does
 * exactly that.
 */
function AuthSilentCallbackPage() {
  useEffect(() => {
    const OIDC_AUTHORITY = import.meta.env.VITE_OIDC_AUTHORITY ?? '';
    const OIDC_CLIENT_ID = import.meta.env.VITE_OIDC_CLIENT_ID ?? '';
    const OIDC_REDIRECT_URI =
      import.meta.env.VITE_OIDC_REDIRECT_URI ?? `${window.location.origin}/auth/callback`;

    if (!OIDC_AUTHORITY || !OIDC_CLIENT_ID) return;

    const manager = new UserManager({
      authority: OIDC_AUTHORITY,
      client_id: OIDC_CLIENT_ID,
      redirect_uri: OIDC_REDIRECT_URI,
    });

    manager.signinSilentCallback().catch(() => {
      // Silent renewal failed — the parent frame's UserManager will emit
      // a silentRenewError event, which AuthProvider handles by clearing state.
    });
  }, []);

  return null;
}

export const Route = createFileRoute('/auth/silent-callback')({
  component: AuthSilentCallbackPage,
});
