import { Center, Loader } from '@mantine/core';
import { createFileRoute, redirect, useNavigate } from '@tanstack/react-router';
import { useEffect } from 'react';
import { useAuth } from '../auth/AuthProvider';

export const Route = createFileRoute('/')({ 
  beforeLoad: ({ context }) => {
    // If auth state is already resolved, redirect immediately without rendering.
    if (context.auth && !context.auth.isLoading) {
      throw redirect({ to: context.auth.isAuthenticated ? '/quests' : '/login' });
    }
  },
  component: IndexPage,
});

/**
 * Shown only while the auth state is still loading (isLoading = true).
 * Once auth resolves, a useEffect-driven navigation takes over.
 */
function IndexPage() {
  const { isLoading, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isLoading) {
      navigate({ to: isAuthenticated ? '/quests' : '/login', replace: true });
    }
  }, [isLoading, isAuthenticated, navigate]);

  return (
    <Center h="50vh">
      <Loader />
    </Center>
  );
}
