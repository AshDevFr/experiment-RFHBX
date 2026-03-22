import { Button, Center, Divider, Paper, Stack, Text, Title } from '@mantine/core';
import { createFileRoute, redirect, useRouter } from '@tanstack/react-router';
import { useState } from 'react';
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

const isDevBypass = import.meta.env.VITE_DEV_AUTH_BYPASS === 'true';

function LoginPage() {
  const { login, devLogin, isLoading } = useAuth();
  const { returnTo } = Route.useSearch();
  const router = useRouter();
  const [devLoading, setDevLoading] = useState(false);

  const handleSignIn = () => {
    login(returnTo ?? '/quests');
  };

  const handleDevLogin = async () => {
    setDevLoading(true);
    try {
      await devLogin();
      await router.navigate({ to: returnTo ?? '/quests' });
    } catch (err) {
      console.error('Dev login failed:', err);
    } finally {
      setDevLoading(false);
    }
  };

  return (
    <Center h="80vh">
      <Paper p="xl" miw={420} w={440} withBorder>
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
          {isDevBypass && (
            <>
              <Divider w="100%" label="or" labelPosition="center" />
              <Button
                fullWidth
                variant="outline"
                color="yellow"
                onClick={handleDevLogin}
                loading={devLoading}
                size="md"
                data-testid="dev-login-btn"
              >
                Dev Login (bypass OIDC)
              </Button>
              <Text size="xs" c="dimmed" ta="center">
                DEV_AUTH_BYPASS active — dev@mordors-edge.local
              </Text>
            </>
          )}
        </Stack>
      </Paper>
    </Center>
  );
}
