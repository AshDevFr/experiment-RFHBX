import { Alert, Badge, Container, Group, Loader, Paper, Stack, Text, Title } from '@mantine/core';
import { createFileRoute } from '@tanstack/react-router';
import { useEffect, useState } from 'react';
import { PixelSprite } from '../components/PixelSprite';
import { api } from '../lib/api';
import { type Health, healthSchema } from '../schemas/health';

function IndexPage() {
  const [health, setHealth] = useState<Health | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .get('/api/health')
      .then((res) => {
        const parsed = healthSchema.safeParse(res.data);
        if (parsed.success) {
          setHealth(parsed.data);
        } else {
          setError('Invalid response format from server');
        }
      })
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : 'Failed to reach API';
        setError(message);
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <Container size="sm" py="xl">
      <Stack align="center" gap="xl">
        <PixelSprite name="ring" size={72} />

        <Title order={1} ta="center">
          MORDOR'S EDGE
        </Title>

        <Text c="dimmed" size="sm" ta="center">
          ONE RING TO RULE THEM ALL
        </Text>

        <Paper p="xl" withBorder w="100%">
          <Title order={3} mb="md">
            API STATUS
          </Title>

          {loading && (
            <Group>
              <Loader size="sm" />
              <Text size="sm">Connecting to API...</Text>
            </Group>
          )}

          {error && (
            <Alert color="red" title="CONNECTION FAILED">
              {error}
            </Alert>
          )}

          {health && (
            <Stack gap="sm">
              <Group>
                <Text size="sm" c="dimmed" w={120}>
                  STATUS
                </Text>
                <Badge color={health.status === 'ok' ? 'retro' : 'red'} variant="filled">
                  {health.status.toUpperCase()}
                </Badge>
              </Group>
              <Group>
                <Text size="sm" c="dimmed" w={120}>
                  VERSION
                </Text>
                <Text size="sm" ff="monospace">
                  {health.version}
                </Text>
              </Group>
              <Group>
                <Text size="sm" c="dimmed" w={120}>
                  ENVIRONMENT
                </Text>
                <Text size="sm" ff="monospace">
                  {health.environment}
                </Text>
              </Group>
            </Stack>
          )}
        </Paper>
      </Stack>
    </Container>
  );
}

export const Route = createFileRoute('/')({ component: IndexPage });
