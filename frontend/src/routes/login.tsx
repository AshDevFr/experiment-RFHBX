import { Button, Center, Paper, Stack, Text, Title } from '@mantine/core';
import { createFileRoute, redirect } from '@tanstack/react-router';
import { z } from 'zod';
import { useAuth } from '../auth/AuthProvider';

// ---------------------------------------------------------------------------
// Search params schema
// ---------------------------------------------------------------------------

const loginSearchSchema = z.object({
  /** Where to send the user after a successful login. */
  returnTo: z.string().optional(),
});

// ---------------------------------------------------------------------------
// Route definition
// ---------------------------------------------------------------------------

export const Route = createFileRoute('/login')({
  validateSearch: loginSearchSchema,
  beforeLoad: ({ context }) => {
    // Already authenticated — skip the login page entirely.
    if (context.auth && !context.auth.isLoading && context.auth.isAuthenticated) {
      throw redirect({ to: '/quests' });
    }
  },
  component: LoginPage,
});

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

function LoginPage() {
  const { login, isLoading } = useAuth();
  const { returnTo } = Route.useSearch();

  const handleSignIn = () => {
    login(returnTo ?? '/quests');
  };

  return (
    <Center h="80vh">
      <Paper p="xl" w={360} withBorder>
        <Stack align="center" gap="lg">
          <Title order={2} ta="center">
            MORDOR'S EDGE
          </Title>
          <Text size="sm" c="dimmed" ta="center">
            ONE RING TO RULE THEM ALL
          </Text>
          <Button fullWidth onClick={handleSignIn} loading={isLoading} size="md">
            Sign in with OIDC
          </Button>
        </Stack>
      </Paper>
    </Center>
  );
}
