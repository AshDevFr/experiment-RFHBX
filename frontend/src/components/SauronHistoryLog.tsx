import { Badge, Group, Paper, ScrollArea, Stack, Text } from '@mantine/core';
import type { SauronGaze } from '../hooks/useSauronGazeChannel';

interface SauronHistoryLogProps {
  events: SauronGaze[];
}

function threatColor(level: number): string {
  if (level <= 2) return 'green';
  if (level <= 4) return 'yellow';
  if (level <= 6) return 'orange';
  return 'red';
}

function formatTimestamp(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString();
  } catch {
    return iso;
  }
}

/**
 * Scrollable history log showing the most recent Sauron gaze events.
 * Newest entries appear at the top.
 */
export function SauronHistoryLog({ events }: SauronHistoryLogProps) {
  if (events.length === 0) {
    return (
      <Text c="dimmed" size="sm" ta="center" data-testid="history-empty">
        No events received yet. Waiting for the Eye to stir…
      </Text>
    );
  }

  return (
    <ScrollArea h={360} data-testid="history-log">
      <Stack gap="xs">
        {events.map((event) => (
          <Paper
            key={`${event.watched_at}-${event.region}`}
            p="sm"
            withBorder
            data-testid="history-entry"
          >
            <Group justify="space-between" wrap="nowrap">
              <Group gap="xs" wrap="nowrap">
                <Badge color={threatColor(event.threat_level)} variant="filled" size="sm">
                  {event.threat_level}
                </Badge>
                <Text size="sm" fw={500}>
                  {event.region}
                </Text>
              </Group>
              <Text size="xs" c="dimmed">
                {formatTimestamp(event.watched_at)}
              </Text>
            </Group>
            <Text size="xs" c="dimmed" mt={4}>
              {event.message}
            </Text>
          </Paper>
        ))}
      </Stack>
    </ScrollArea>
  );
}
