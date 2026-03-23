import { Center, Loader } from '@mantine/core';
import { createFileRoute, Outlet, useNavigate, useRouterState } from '@tanstack/react-router';
import { useEffect } from 'react';
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
 */
function AuthenticatedLayout() {
  const { isLoading, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useRouterState({ select: (s) => s.location });

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      const searchStr = location.searchStr ?? '';
      navigate({
        to: '/login',
        search: { returnTo: location.pathname + searchStr },
      });
    }
  }, [isLoading, isAuthenticated, navigate, location.pathname, location.searchStr]);

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
