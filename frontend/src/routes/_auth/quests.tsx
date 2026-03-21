import {
  Alert,
  Container,
  Group,
  Select,
  SimpleGrid,
  Skeleton,
  Stack,
  Text,
  Title,
} from '@mantine/core';
import { createFileRoute } from '@tanstack/react-router';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { CableStatus } from '../../components/CableStatus';
import { QuestCard } from '../../components/QuestCard';
import { QuestDetailModal } from '../../components/QuestDetailModal';
import { useQuestEventsChannel } from '../../hooks/useQuestEventsChannel';
import { useQuests } from '../../hooks/useQuests';
import { api } from '../../lib/api';
import type { Quest } from '../../schemas/quest';

export const Route = createFileRoute('/_auth/quests')({
  component: QuestsPage,
});

// ---------------------------------------------------------------------------
// Skeleton placeholder while loading
// ---------------------------------------------------------------------------
function QuestGridSkeleton() {
  return (
    <SimpleGrid cols={{ base: 1, sm: 2, md: 3 }} spacing="md">
      {Array.from({ length: 6 }).map((_, i) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: skeleton placeholders have no identity
        <Skeleton key={i} height={140} radius="md" />
      ))}
    </SimpleGrid>
  );
}

// ---------------------------------------------------------------------------
// Status filter options
// ---------------------------------------------------------------------------
const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'active', label: 'Active' },
  { value: 'completed', label: 'Completed' },
  { value: 'failed', label: 'Failed' },
];

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------
export function QuestsPage() {
  const { quests, isLoading, error } = useQuests();
  const { latestEvent, connectionStatus } = useQuestEventsChannel();
  const [liveQuests, setLiveQuests] = useState<Quest[]>([]);
  const [selectedQuest, setSelectedQuest] = useState<Quest | null>(null);
  const [statusFilter, setStatusFilter] = useState<string | null>(null);
  const [startError, setStartError] = useState<string | null>(null);

  // Seed liveQuests from the initial REST fetch.
  useEffect(() => {
    if (!isLoading && quests.length > 0) {
      setLiveQuests(quests);
    }
  }, [quests, isLoading]);

  // Apply real-time patch updates from QuestEventsChannel.
  useEffect(() => {
    if (!latestEvent) return;

    const patch: Partial<Quest> = {};
    if ('status' in latestEvent && typeof latestEvent.status === 'string') {
      patch.status = latestEvent.status as Quest['status'];
    }
    if ('progress' in latestEvent && typeof latestEvent.progress === 'number') {
      patch.progress = latestEvent.progress;
    }
    if (Object.keys(patch).length === 0) return;

    const applyPatch = (q: Quest): Quest =>
      q.id === latestEvent.quest_id ? { ...q, ...patch } : q;

    setLiveQuests((prev) => prev.map(applyPatch));
    setSelectedQuest((prev) => (prev ? applyPatch(prev) : null));
  }, [latestEvent]);

  // Client-side filtering by status.
  const filtered = useMemo(
    () => liveQuests.filter((q) => !statusFilter || q.status === statusFilter),
    [liveQuests, statusFilter],
  );

  const handleStartQuest = useCallback(async (questId: number) => {
    setStartError(null);
    try {
      await api.patch(`/api/v1/quests/${questId}`, {
        quest: { status: 'active' },
      });
      const apply = (q: Quest): Quest =>
        q.id === questId ? { ...q, status: 'active' as const } : q;
      setLiveQuests((prev) => prev.map(apply));
      setSelectedQuest((prev) => (prev ? apply(prev) : null));
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to start quest';
      setStartError(message);
    }
  }, []);

  return (
    <Container size="xl">
      <Group justify="space-between" align="center" mb="md">
        <Title order={2}>QUESTS</Title>
        <CableStatus status={connectionStatus} />
      </Group>

      {/* Fetch error */}
      {error && (
        <Alert color="red" title="Failed to load quests" mb="md" data-testid="error-banner">
          {error}
        </Alert>
      )}

      {/* Start-quest error */}
      {startError && (
        <Alert
          color="orange"
          title="Failed to start quest"
          mb="md"
          data-testid="start-error-banner"
          withCloseButton
          onClose={() => setStartError(null)}
        >
          {startError}
        </Alert>
      )}

      {/* Disconnect banner */}
      {connectionStatus === 'disconnected' && (
        <Alert
          color="yellow"
          title="Real-time updates unavailable"
          mb="md"
          data-testid="disconnect-banner"
        >
          WebSocket connection lost. Quest updates may be delayed.
        </Alert>
      )}

      {/* Status filter */}
      <Group mb="lg" align="flex-end">
        <Select
          label="Filter by Status"
          placeholder="All statuses"
          data={STATUS_OPTIONS}
          value={statusFilter}
          onChange={setStatusFilter}
          clearable
          style={{ minWidth: 200 }}
          aria-label="Filter by status"
        />
      </Group>

      {/* Loading state */}
      {isLoading && <QuestGridSkeleton />}

      {/* Quest grid */}
      {!isLoading &&
        !error &&
        (filtered.length === 0 ? (
          <Stack align="center" mt="xl">
            <Text c="dimmed" size="sm">
              No quests match the selected filter.
            </Text>
          </Stack>
        ) : (
          <SimpleGrid cols={{ base: 1, sm: 2, md: 3 }} spacing="md">
            {filtered.map((quest) => (
              <QuestCard key={quest.id} quest={quest} onClick={setSelectedQuest} />
            ))}
          </SimpleGrid>
        ))}

      {/* Detail modal */}
      <QuestDetailModal
        quest={selectedQuest}
        onClose={() => setSelectedQuest(null)}
        onStart={handleStartQuest}
      />
    </Container>
  );
}
