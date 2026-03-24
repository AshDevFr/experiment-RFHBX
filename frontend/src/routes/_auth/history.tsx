import {
  Alert,
  Badge,
  Container,
  Group,
  MultiSelect,
  Pagination,
  Skeleton,
  Stack,
  Table,
  Text,
  TextInput,
  Title,
} from '@mantine/core';
import { useDebouncedValue } from '@mantine/hooks';
import { createFileRoute } from '@tanstack/react-router';
import { useEffect, useState } from 'react';
import { useQuestEventHistory } from '../../hooks/useQuestEventHistory';
import {
  EVENT_TYPE_COLORS,
  EVENT_TYPE_LABELS,
  EVENT_TYPES,
  type EventType,
} from '../../schemas/questEvent';

export const Route = createFileRoute('/_auth/history')({
  component: HistoryPage,
});

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const EVENT_TYPE_OPTIONS = EVENT_TYPES.map((t) => ({
  value: t,
  label: EVENT_TYPE_LABELS[t],
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatTimestamp(iso: string): string {
  return new Date(iso).toLocaleString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

// ---------------------------------------------------------------------------
// Skeleton rows while loading
// ---------------------------------------------------------------------------

function TableSkeleton() {
  return (
    <>
      {Array.from({ length: 8 }).map((_, i) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: skeleton placeholders have no identity
        <Table.Tr key={i}>
          <Table.Td>
            <Skeleton height={16} radius="sm" />
          </Table.Td>
          <Table.Td>
            <Skeleton height={16} radius="sm" />
          </Table.Td>
          <Table.Td>
            <Skeleton height={20} width={80} radius="xl" />
          </Table.Td>
          <Table.Td>
            <Skeleton height={16} radius="sm" />
          </Table.Td>
        </Table.Tr>
      ))}
    </>
  );
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

export function HistoryPage() {
  const { events, meta, isLoading, error, filters, setEventTypes, setQuestTitle, setPage } =
    useQuestEventHistory();

  // Local state for text input — debounced before hitting the API
  const [questTitleInput, setQuestTitleInput] = useState('');
  const [debouncedQuestTitle] = useDebouncedValue(questTitleInput, 300);

  // Sync debounced value to the hook
  useEffect(() => {
    setQuestTitle(debouncedQuestTitle);
  }, [debouncedQuestTitle, setQuestTitle]);

  const totalPages = meta?.total_pages ?? 1;

  return (
    <Container size="xl">
      <Title order={2} mb="md">
        EVENT HISTORY
      </Title>

      {/* Filters */}
      <Group mb="lg" align="flex-end" wrap="wrap">
        <MultiSelect
          label="Filter by Event Type"
          placeholder="All types"
          data={EVENT_TYPE_OPTIONS}
          value={filters.eventTypes}
          onChange={(vals) => setEventTypes(vals as EventType[])}
          clearable
          style={{ minWidth: 260 }}
          aria-label="Filter by event type"
          data-testid="event-type-filter"
        />
        <TextInput
          label="Filter by Quest Title"
          placeholder="Search quest title…"
          value={questTitleInput}
          onChange={(e) => setQuestTitleInput(e.currentTarget.value)}
          style={{ minWidth: 240 }}
          aria-label="Filter by quest title"
          data-testid="quest-title-filter"
        />
      </Group>

      {/* Error state */}
      {error && (
        <Alert color="red" title="Failed to load event history" mb="md" data-testid="error-banner">
          {error}
        </Alert>
      )}

      {/* Summary */}
      {!isLoading && !error && meta && (
        <Text size="sm" c="dimmed" mb="xs" data-testid="event-count">
          {meta.total} event{meta.total !== 1 ? 's' : ''}
          {meta.total_pages > 1 ? ` — page ${meta.page} of ${meta.total_pages}` : ''}
        </Text>
      )}

      {/* Table */}
      <Table striped highlightOnHover withTableBorder withColumnBorders data-testid="events-table">
        <Table.Thead>
          <Table.Tr>
            <Table.Th style={{ whiteSpace: 'nowrap' }}>Timestamp</Table.Th>
            <Table.Th>Quest</Table.Th>
            <Table.Th>Type</Table.Th>
            <Table.Th>Message</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {isLoading ? (
            <TableSkeleton />
          ) : !error && events.length === 0 ? (
            <Table.Tr>
              <Table.Td colSpan={4}>
                <Stack align="center" py="xl">
                  <Text c="dimmed" size="sm" data-testid="empty-state">
                    No events match the selected filters.
                  </Text>
                </Stack>
              </Table.Td>
            </Table.Tr>
          ) : (
            events.map((event) => (
              <Table.Tr key={event.id} data-testid="event-row">
                <Table.Td style={{ whiteSpace: 'nowrap', fontSize: '0.8rem' }}>
                  {formatTimestamp(event.created_at)}
                </Table.Td>
                <Table.Td>{event.quest_title}</Table.Td>
                <Table.Td>
                  <Badge
                    color={EVENT_TYPE_COLORS[event.event_type]}
                    variant="light"
                    size="sm"
                    data-testid={`badge-${event.event_type}`}
                  >
                    {EVENT_TYPE_LABELS[event.event_type]}
                  </Badge>
                </Table.Td>
                <Table.Td>
                  <Text size="sm" c={event.message ? undefined : 'dimmed'}>
                    {event.message ?? '—'}
                  </Text>
                </Table.Td>
              </Table.Tr>
            ))
          )}
        </Table.Tbody>
      </Table>

      {/* Pagination */}
      {!isLoading && totalPages > 1 && (
        <Group justify="center" mt="lg">
          <Pagination
            total={totalPages}
            value={filters.page}
            onChange={setPage}
            aria-label="Event history pagination"
            data-testid="pagination"
          />
        </Group>
      )}
    </Container>
  );
}
