import {
  Alert,
  Badge,
  Button,
  Card,
  Container,
  Group,
  SimpleGrid,
  Stack,
  Text,
  Title,
} from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { createFileRoute } from '@tanstack/react-router';
import { useChaos } from '../../hooks/useChaos';
import type { ChaosActionResult } from '../../schemas/chaos';

export const Route = createFileRoute('/_auth/chaos')({
  component: ChaosPage,
});

// ---------------------------------------------------------------------------
// Result display
// ---------------------------------------------------------------------------

function formatResult(result: ChaosActionResult): { label: string; details: string } {
  switch (result.type) {
    case 'wound_character':
      return {
        label: 'Character wounded',
        details: `${result.result.affected.name} has fallen (status: ${result.result.affected.status})`,
      };
    case 'fail_quest':
      return {
        label: 'Quest failed',
        details: `"${result.result.affected.title}" sabotaged — ${result.result.affected.members_reset} member(s) returned to idle`,
      };
    case 'spike_threat':
      return {
        label: 'Threat spiked',
        details: `${result.result.affected.region} — threat level surged to ${result.result.affected.threat_level}`,
      };
    case 'stop_simulation':
      return {
        label: 'Simulation halted',
        details: result.result.affected.message,
      };
    default: {
      const _exhaustive: never = result;
      throw new Error(`Unknown chaos result type: ${JSON.stringify(_exhaustive)}`);
    }
  }
}

interface ResultCardProps {
  result: ChaosActionResult;
}

export function ChaosResultCard({ result }: ResultCardProps) {
  const { label, details } = formatResult(result);
  return (
    <Card shadow="sm" padding="md" radius="md" withBorder data-testid="result-card">
      <Group gap="sm" align="center">
        <Badge color="red" variant="filled" size="lg">
          CHAOS APPLIED
        </Badge>
        <Text fw={600}>{label}</Text>
      </Group>
      <Text mt="xs" c="dimmed" size="sm" data-testid="result-details">
        {details}
      </Text>
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Chaos action card
// ---------------------------------------------------------------------------

interface ActionCardProps {
  title: string;
  description: string;
  buttonLabel: string;
  buttonColor: string;
  testId: string;
  disabled: boolean;
  onClick: () => void;
}

export function ChaosActionCard({
  title,
  description,
  buttonLabel,
  buttonColor,
  testId,
  disabled,
  onClick,
}: ActionCardProps) {
  return (
    <Card shadow="sm" padding="md" radius="md" withBorder>
      <Stack gap="sm">
        <Title order={5}>{title}</Title>
        <Text size="sm" c="dimmed">
          {description}
        </Text>
        <Button
          color={buttonColor}
          disabled={disabled}
          onClick={onClick}
          data-testid={testId}
          fullWidth
        >
          {buttonLabel}
        </Button>
      </Stack>
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

function ChaosPage() {
  const { result, error, isLoading, woundCharacter, failQuest, spikeThreat, stopSimulation } =
    useChaos();

  async function handleWoundCharacter() {
    const ok = await woundCharacter();
    if (ok) {
      notifications.show({
        title: 'Chaos injected',
        message: 'A character has been wounded.',
        color: 'red',
      });
    }
  }

  async function handleFailQuest() {
    const ok = await failQuest();
    if (ok) {
      notifications.show({
        title: 'Chaos injected',
        message: 'A quest has been sabotaged.',
        color: 'red',
      });
    }
  }

  async function handleSpikeThreat() {
    const ok = await spikeThreat();
    if (ok) {
      notifications.show({
        title: 'Chaos injected',
        message: 'Threat level spiked to maximum!',
        color: 'orange',
      });
    }
  }

  async function handleStopSimulation() {
    const ok = await stopSimulation();
    if (ok) {
      notifications.show({
        title: 'Chaos injected',
        message: 'The simulation has been halted.',
        color: 'dark',
      });
    }
  }

  return (
    <Container size="lg" py="xl">
      <Title order={2} mb="lg">
        Chaos Panel
      </Title>

      <Text c="dimmed" mb="xl">
        Deliberately inject failures into the simulation for disaster recovery training. Each action
        triggers an immediate adverse event.
      </Text>

      {error && (
        <Alert color="red" title="Chaos action failed" mb="md" data-testid="error-alert">
          {error}
        </Alert>
      )}

      {result && <ChaosResultCard result={result} />}

      <SimpleGrid cols={{ base: 1, sm: 2 }} mt="xl">
        <ChaosActionCard
          title="Wound Character"
          description="Set a random on-quest character to fallen, remove from quest, and log casualty event."
          buttonLabel="Wound Character"
          buttonColor="red"
          testId="btn-wound-character"
          disabled={isLoading}
          onClick={handleWoundCharacter}
        />
        <ChaosActionCard
          title="Fail Quest"
          description="Immediately fail a random active quest, reset progress to 0, and return members to idle."
          buttonLabel="Fail Quest"
          buttonColor="red"
          testId="btn-fail-quest"
          disabled={isLoading}
          onClick={handleFailQuest}
        />
        <ChaosActionCard
          title="Spike Threat"
          description="Surge threat level to 10 via the Eye of Sauron. Decays naturally on the next worker tick."
          buttonLabel="Spike Threat"
          buttonColor="orange"
          testId="btn-spike-threat"
          disabled={isLoading}
          onClick={handleSpikeThreat}
        />
        <ChaosActionCard
          title="Stop Simulation"
          description="Halt the simulation and broadcast a Sauron event announcing the halt."
          buttonLabel="Stop Simulation"
          buttonColor="dark"
          testId="btn-stop-simulation"
          disabled={isLoading}
          onClick={handleStopSimulation}
        />
      </SimpleGrid>
    </Container>
  );
}
