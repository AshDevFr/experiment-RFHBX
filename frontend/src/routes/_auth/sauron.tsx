import { Alert, Center, Container, Group, Loader, Stack, Text, Title } from '@mantine/core';
import { createFileRoute } from '@tanstack/react-router';
import { useRef, useState } from 'react';
import { CableStatus } from '../../components/CableStatus';
import { SauronHistoryLog } from '../../components/SauronHistoryLog';
import { ThreatLevelIndicator } from '../../components/ThreatLevelIndicator';
import { type SauronGaze, useSauronGazeChannel } from '../../hooks/useSauronGazeChannel';

export const Route = createFileRoute('/_auth/sauron')({
  component: SauronPage,
});

const MAX_HISTORY = 50;

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------
export function SauronPage() {
  const { latestGaze, connectionStatus } = useSauronGazeChannel();
  const [history, setHistory] = useState<SauronGaze[]>([]);
  const prevGazeRef = useRef<SauronGaze | null>(null);

  // Append to history whenever a new gaze arrives.
  // We compare by reference to the latestGaze object to avoid duplicates.
  if (latestGaze && latestGaze !== prevGazeRef.current) {
    prevGazeRef.current = latestGaze;
    // Prepend newest and cap at MAX_HISTORY — inline to avoid useEffect lag.
    setHistory((prev) => [latestGaze, ...prev].slice(0, MAX_HISTORY));
  }

  return (
    <Container size="md">
      <Group justify="space-between" align="center" mb="md">
        <Title order={2}>EYE OF SAURON</Title>
        <CableStatus status={connectionStatus} />
      </Group>

      {/* Disconnect banner */}
      {connectionStatus === 'disconnected' && (
        <Alert
          color="yellow"
          title="Real-time updates unavailable"
          mb="md"
          data-testid="disconnect-banner"
        >
          WebSocket connection lost. Threat data may be stale.
        </Alert>
      )}

      {/* Connecting state — no data yet */}
      {connectionStatus === 'connecting' && !latestGaze && (
        <Center h={200}>
          <Stack align="center" gap="xs">
            <Loader size="lg" />
            <Text c="dimmed" size="sm" data-testid="loading-state">
              Awaiting signal from the Eye…
            </Text>
          </Stack>
        </Center>
      )}

      {/* Live threat indicator */}
      {latestGaze && (
        <Stack gap="lg">
          <ThreatLevelIndicator
            level={latestGaze.threat_level}
            region={latestGaze.region}
            message={latestGaze.message}
          />

          <Text size="xs" c="dimmed" ta="center">
            Last update: {new Date(latestGaze.watched_at).toLocaleString()}
          </Text>

          <Title order={4} mt="sm">
            History
          </Title>
          <SauronHistoryLog events={history} />
        </Stack>
      )}
    </Container>
  );
}
