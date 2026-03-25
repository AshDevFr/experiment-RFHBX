import { Badge, Group, Paper, ScrollArea, Stack, Text } from '@mantine/core';
import { useRef, useState } from 'react';
import { useQuestEventsChannel } from '../hooks/useQuestEventsChannel';
import { EVENT_TYPE_COLORS, EVENT_TYPE_LABELS } from '../schemas/questEvent';

/** Shape of a quest event broadcast payload from ActionCable. */
interface LiveQuestEvent {
  event_type: string;
  quest_id?: number;
  quest_name?: string;
  region?: string;
  message?: string;
  occurred_at?: string;
  data?: Record<string, unknown>;
}

const MAX_EVENTS = 50;

function formatTimestamp(iso: string | undefined): string {
  if (!iso) return '';
  try {
    return new Date(iso).toLocaleTimeString();
  } catch {
    return iso;
  }
}

function eventBadgeColor(eventType: string): string {
  // Cast to EventType to look up the color; fall back to 'gray' for unknown types.
  return EVENT_TYPE_COLORS[eventType as keyof typeof EVENT_TYPE_COLORS] ?? 'gray';
}

function eventBadgeLabel(eventType: string): string {
  return EVENT_TYPE_LABELS[eventType as keyof typeof EVENT_TYPE_LABELS] ?? eventType;
}

/**
 * Real-time quest event feed subscribing to the global QuestEventsChannel.
 * Renders each event with a color-coded badge; `level_up` events use a gold badge.
 * Newest entries appear at the top, capped at MAX_EVENTS.
 */
export function QuestEventFeed() {
  const { latestEvent } = useQuestEventsChannel();
  const [events, setEvents] = useState<LiveQuestEvent[]>([]);
  const prevEventRef = useRef<typeof latestEvent | null>(null);

  // Append to the feed whenever a new event arrives.
  // Compare by reference to avoid duplicate pushes on re-renders.
  if (latestEvent && latestEvent !== prevEventRef.current) {
    prevEventRef.current = latestEvent;
    const live: LiveQuestEvent = {
      event_type: (latestEvent.event_type as string) ?? latestEvent.type ?? 'unknown',
      quest_id: latestEvent.quest_id,
      quest_name: latestEvent.quest_name as string | undefined,
      region: latestEvent.region as string | undefined,
      message: latestEvent.message as string | undefined,
      occurred_at: latestEvent.occurred_at as string | undefined,
      data: latestEvent.data as Record<string, unknown> | undefined,
    };
    setEvents((prev) => [live, ...prev].slice(0, MAX_EVENTS));
  }

  if (events.length === 0) {
    return (
      <Text c="dimmed" size="sm" ta="center" data-testid="quest-feed-empty">
        No quest events yet. Awaiting the fellowship's deeds…
      </Text>
    );
  }

  return (
    <ScrollArea h={360} data-testid="quest-event-feed">
      <Stack gap="xs">
        {events.map((event, index) => {
          const badgeColor = eventBadgeColor(event.event_type);
          const badgeLabel = eventBadgeLabel(event.event_type);
          return (
            <Paper
              key={`${event.occurred_at ?? index}-${event.quest_id ?? index}`}
              p="sm"
              withBorder
              data-testid="quest-feed-entry"
            >
              <Group justify="space-between" wrap="nowrap">
                <Group gap="xs" wrap="nowrap">
                  <Badge
                    color={badgeColor}
                    variant="filled"
                    size="sm"
                    data-testid={`badge-${event.event_type}`}
                  >
                    {badgeLabel}
                  </Badge>
                  {event.quest_name && (
                    <Text size="sm" fw={500}>
                      {event.quest_name}
                    </Text>
                  )}
                </Group>
                {event.occurred_at && (
                  <Text size="xs" c="dimmed">
                    {formatTimestamp(event.occurred_at)}
                  </Text>
                )}
              </Group>
              {event.message && (
                <Text size="xs" c="dimmed" mt={4}>
                  {event.message}
                </Text>
              )}
            </Paper>
          );
        })}
      </Stack>
    </ScrollArea>
  );
}
