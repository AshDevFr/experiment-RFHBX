import { Center, Loader } from '@mantine/core';
import { createFileRoute, Outlet, useNavigate, useRouterState } from '@tanstack/react-router';
import { useEffect, useRef } from 'react';
import { useAuth } from '../auth/AuthProvider';
import { requireAuth } from '../auth/authGuard';

export const Route = createFileRoute('/_auth')({
  beforeLoad: ({ context, location }) => requireAuth(context.auth, location),
  component: AuthenticatedLayout,
});

/**
 * Wraps all protected routes.  Handles the async loading case:
 * `beforeLoad` covers the fast path (auth already resolved), and the
 * component's `useEffect` covers the slower path where auth resolves
 * after the route has already begun rendering.
 *
 * The intended destination is captured once at mount via `useRef` and kept
 * out of the effect's dependency array.  This prevents an infinite loop where
 * calling `navigate('/login?returnTo=…')` updates the router location, which
 * would otherwise re-trigger the effect and produce recursively nested
 * `returnTo` parameters.
 */
function AuthenticatedLayout() {
  const { isLoading, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useRouterState({ select: (s) => s.location });

  // Capture the intended destination at mount time only.  Using a ref instead
  // of state means this value is stable across re-renders and will never cause
  // the effect to fire again after the initial redirect.
  const intendedDestRef = useRef(location.pathname + (location.searchStr ?? ''));

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      navigate({
        to: '/login',
        search: { returnTo: intendedDestRef.current },
      });
    }
  }, [isLoading, isAuthenticated, navigate]);

  if (isLoading) {
    return (
      <Center h="50vh">
        <Loader />
      </Center>
    );
  }

  if (!isAuthenticated) return null;

  return <Outlet />;
}
