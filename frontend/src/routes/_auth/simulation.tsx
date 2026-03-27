import {
  Alert,
  Badge,
  Button,
  Card,
  Container,
  Divider,
  Group,
  NumberInput,
  Select,
  SimpleGrid,
  Skeleton,
  Stack,
  Text,
  Title,
} from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { createFileRoute } from '@tanstack/react-router';
import { useEffect, useState } from 'react';
import { useSimulation } from '../../hooks/useSimulation';
import type { SimulationConfig, SimulationConfigUpdate } from '../../schemas/simulation';

export const Route = createFileRoute('/_auth/simulation')({
  component: SimulationPage,
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function statusColor(running: boolean): string {
  return running ? 'green' : 'gray';
}

function statusLabel(running: boolean): string {
  return running ? 'RUNNING' : 'STOPPED';
}

// ---------------------------------------------------------------------------
// Status panel
// ---------------------------------------------------------------------------

interface StatusPanelProps {
  config: SimulationConfig;
  isActing: boolean;
  onStart: () => void;
  onStop: () => void;
}

export function SimulationStatusPanel({ config, isActing, onStart, onStop }: StatusPanelProps) {
  return (
    <Card shadow="sm" padding="md" radius="md" withBorder data-testid="status-panel">
      <Stack gap="md">
        <Group justify="space-between" align="center">
          <Title order={4}>Simulation Status</Title>
          <Badge
            color={statusColor(config.running)}
            size="lg"
            variant="filled"
            data-testid="status-badge"
          >
            {statusLabel(config.running)}
          </Badge>
        </Group>

        <SimpleGrid cols={{ base: 2, sm: 3 }} spacing="sm">
          <Stack gap={2}>
            <Text size="xs" c="dimmed" tt="uppercase" fw={600}>
              Mode
            </Text>
            <Badge color="blue" variant="light" data-testid="mode-badge">
              {config.mode}
            </Badge>
          </Stack>

          <Stack gap={2}>
            <Text size="xs" c="dimmed" tt="uppercase" fw={600}>
              Tick Count
            </Text>
            <Text fw={700} data-testid="tick-count">
              {config.tick_count ?? 0}
            </Text>
          </Stack>

          <Stack gap={2}>
            <Text size="xs" c="dimmed" tt="uppercase" fw={600}>
              Campaign Position
            </Text>
            <Text fw={700} data-testid="campaign-position">
              {config.campaign_position}
            </Text>
          </Stack>
        </SimpleGrid>

        <Group gap="sm">
          <Button
            color="green"
            disabled={config.running || isActing}
            loading={isActing && !config.running}
            onClick={onStart}
            data-testid="start-button"
          >
            Start
          </Button>
          <Button
            color="red"
            variant="outline"
            disabled={!config.running || isActing}
            loading={isActing && config.running}
            onClick={onStop}
            data-testid="stop-button"
          >
            Stop
          </Button>
        </Group>
      </Stack>
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Config form — validation and form state
// ---------------------------------------------------------------------------

interface ConfigFormValues {
  progress_min: number | string;
  progress_max: number | string;
  mode: 'campaign' | 'random';
}

interface ConfigFormErrors {
  progress_min?: string;
  progress_max?: string;
}

export function validateConfigForm(values: ConfigFormValues): ConfigFormErrors {
  const errors: ConfigFormErrors = {};

  const min = Number(values.progress_min);
  const max = Number(values.progress_max);

  if (!Number.isFinite(min) || min < 0 || min > 1) {
    errors.progress_min = 'Progress min must be between 0 and 1';
  }
  if (!Number.isFinite(max) || max < 0 || max > 1) {
    errors.progress_max = 'Progress max must be between 0 and 1';
  }
  if (Number.isFinite(min) && Number.isFinite(max) && min >= max) {
    errors.progress_min = errors.progress_min ?? 'Progress min must be less than progress max';
    errors.progress_max = errors.progress_max ?? 'Progress max must be greater than progress min';
  }

  return errors;
}

interface ConfigFormProps {
  config: SimulationConfig;
  isActing: boolean;
  onSubmit: (update: SimulationConfigUpdate) => Promise<void>;
}

const MODE_OPTIONS = [
  { value: 'campaign', label: 'Campaign' },
  { value: 'random', label: 'Random' },
];

export function SimulationConfigForm({ config, isActing, onSubmit }: ConfigFormProps) {
  const [values, setValues] = useState<ConfigFormValues>({
    progress_min: config.progress_min,
    progress_max: config.progress_max,
    mode: config.mode,
  });
  const [formErrors, setFormErrors] = useState<ConfigFormErrors>({});
  const [submitting, setSubmitting] = useState(false);

  // Sync form when upstream config changes (e.g. after polling refresh)
  useEffect(() => {
    setValues({
      progress_min: config.progress_min,
      progress_max: config.progress_max,
      mode: config.mode,
    });
  }, [config.progress_min, config.progress_max, config.mode]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const errors = validateConfigForm(values);
    setFormErrors(errors);
    if (Object.keys(errors).length > 0) return;

    setSubmitting(true);
    try {
      await onSubmit({
        progress_min: Number(values.progress_min),
        progress_max: Number(values.progress_max),
        mode: values.mode,
      });
      notifications.show({
        title: 'Configuration saved',
        message: 'Simulation parameters updated successfully.',
        color: 'green',
      });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Card shadow="sm" padding="md" radius="md" withBorder data-testid="config-form">
      <Title order={4} mb="md">
        Configuration
      </Title>
      <form onSubmit={handleSubmit}>
        <Stack gap="md">
          <Select
            label="Mode"
            data={MODE_OPTIONS}
            value={values.mode}
            onChange={(v) =>
              setValues((prev) => ({ ...prev, mode: (v ?? 'campaign') as 'campaign' | 'random' }))
            }
            data-testid="mode-select"
          />

          <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="md">
            <NumberInput
              label="Progress min"
              description="Minimum tick progress (0-1)"
              min={0}
              max={1}
              step={0.01}
              decimalScale={4}
              value={values.progress_min}
              onChange={(v) => setValues((prev) => ({ ...prev, progress_min: v }))}
              error={formErrors.progress_min}
              data-testid="progress-min-input"
            />
            <NumberInput
              label="Progress max"
              description="Maximum tick progress (0-1)"
              min={0}
              max={1}
              step={0.01}
              decimalScale={4}
              value={values.progress_max}
              onChange={(v) => setValues((prev) => ({ ...prev, progress_max: v }))}
              error={formErrors.progress_max}
              data-testid="progress-max-input"
            />
          </SimpleGrid>

          <Group justify="flex-end">
            <Button
              type="submit"
              loading={submitting || isActing}
              disabled={isActing}
              data-testid="save-config-button"
            >
              Save Configuration
            </Button>
          </Group>
        </Stack>
      </form>
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

export function SimulationPage() {
  const { config, isLoading, error, isActing, start, stop, updateConfig } = useSimulation();

  async function handleStart() {
    await start();
    notifications.show({
      title: 'Simulation started',
      message: 'The simulation engine is now running.',
      color: 'green',
    });
  }

  async function handleStop() {
    await stop();
    notifications.show({
      title: 'Simulation stopped',
      message: 'The simulation engine has been halted.',
      color: 'orange',
    });
  }

  return (
    <Container size="md">
      <Title order={2} mb="md">
        SIMULATION CONTROL
      </Title>

      {error && (
        <Alert color="red" title="Error" mb="md" data-testid="error-alert">
          {error}
        </Alert>
      )}

      {isLoading && !config ? (
        <Stack gap="md">
          <Skeleton height={160} radius="md" />
          <Skeleton height={280} radius="md" />
        </Stack>
      ) : config ? (
        <Stack gap="md">
          <SimulationStatusPanel
            config={config}
            isActing={isActing}
            onStart={handleStart}
            onStop={handleStop}
          />

          <Divider />

          <SimulationConfigForm config={config} isActing={isActing} onSubmit={updateConfig} />
        </Stack>
      ) : null}
    </Container>
  );
}
