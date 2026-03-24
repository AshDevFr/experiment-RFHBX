import {
  Alert,
  Button,
  Container,
  Group,
  Modal,
  Select,
  SimpleGrid,
  Skeleton,
  Stack,
  Text,
  Title,
} from '@mantine/core';
import { notifications } from '@mantine/notifications';
import { createFileRoute } from '@tanstack/react-router';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { CableStatus } from '../../components/CableStatus';
import { QuestCard } from '../../components/QuestCard';
import { QuestDetailModal } from '../../components/QuestDetailModal';
import { useQuestEventsChannel } from '../../hooks/useQuestEventsChannel';
import { useQuests } from '../../hooks/useQuests';
import { api } from '../../lib/api';
import { type Quest, questSchema } from '../../schemas/quest';

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
// Status transition map
// ---------------------------------------------------------------------------
const STATUS_TRANSITIONS: Record<string, string | null> = {
  pending: 'active',
  active: 'completed',
  completed: null,
  failed: null,
};

const STATUS_LABELS: Record<string, string> = {
  pending: 'Pending',
  active: 'Active',
  completed: 'Completed',
  failed: 'Failed',
};

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------
export function QuestsPage() {
  const { quests, isLoading, error, refetch } = useQuests();
  const { latestEvent, connectionStatus } = useQuestEventsChannel();
  const [liveQuests, setLiveQuests] = useState<Quest[]>([]);
  const [selectedQuest, setSelectedQuest] = useState<Quest | null>(null);
  const [statusFilter, setStatusFilter] = useState<string | null>(null);
  const [startError, setStartError] = useState<string | null>(null);
  const [resetModalOpen, setResetModalOpen] = useState(false);
  const [resetting, setResetting] = useState(false);
  const [randomizing, setRandomizing] = useState(false);

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
      const response = await api.patch<unknown>(`/api/v1/quests/${questId}`, {
        quest: { status: 'active' },
      });
      const updated = questSchema.parse(response.data);
      setLiveQuests((prev) => prev.map((q) => (q.id === questId ? updated : q)));
      setSelectedQuest(updated);
      notifications.show({
        title: 'Quest Started',
        message: 'Quest is now active',
        color: 'blue',
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to start quest';
      setStartError(message);
    }
  }, []);

  const handleAdvanceStatus = useCallback(async (quest: Quest) => {
    const nextStatus = STATUS_TRANSITIONS[quest.status];
    if (!nextStatus) return;

    // Optimistic update
    const apply = (q: Quest): Quest =>
      q.id === quest.id ? { ...q, status: nextStatus as Quest['status'] } : q;
    setLiveQuests((prev) => prev.map(apply));

    try {
      await api.patch(`/api/v1/quests/${quest.id}`, {
        quest: { status: nextStatus },
      });
      notifications.show({
        title: 'Status Updated',
        message: `${quest.title} is now ${STATUS_LABELS[nextStatus] ?? nextStatus}`,
        color: 'blue',
      });
    } catch (err: unknown) {
      // Revert optimistic update
      setLiveQuests((prev) => prev.map((q) => (q.id === quest.id ? quest : q)));
      const message = err instanceof Error ? err.message : 'Failed to update quest status';
      notifications.show({ title: 'Error', message, color: 'red' });
    }
  }, []);

  const handleReset = useCallback(async () => {
    setResetting(true);
    try {
      await api.post('/api/v1/quests/reset', { confirm: true });
      notifications.show({
        title: 'Quests Reset',
        message: 'All quests have been reset to pending state',
        color: 'blue',
      });
      setResetModalOpen(false);
      refetch();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to reset quests';
      notifications.show({ title: 'Reset Failed', message, color: 'red' });
    } finally {
      setResetting(false);
    }
  }, [refetch]);

  const handleRandomize = useCallback(async () => {
    setRandomizing(true);
    try {
      await api.post('/api/v1/quests/randomize');
      notifications.show({
        title: 'Assignments Randomized',
        message: 'Quest members have been reassigned randomly',
        color: 'grape',
      });
      refetch();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to randomize assignments';
      notifications.show({ title: 'Randomize Failed', message, color: 'red' });
    } finally {
      setRandomizing(false);
    }
  }, [refetch]);

  return (
    <Container size="xl">
      <Group justify="space-between" align="center" mb="md">
        <Title order={2}>QUESTS</Title>
        <Group gap="sm">
          <CableStatus status={connectionStatus} />
          <Button
            variant="light"
            color="grape"
            size="xs"
            onClick={handleRandomize}
            loading={randomizing}
            disabled={isLoading || resetting}
          >
            Randomize Assignments
          </Button>
          <Button
            variant="light"
            color="red"
            size="xs"
            onClick={() => setResetModalOpen(true)}
            disabled={isLoading || randomizing || resetting}
          >
            Reset All Quests
          </Button>
        </Group>
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
              <QuestCard
                key={quest.id}
                quest={quest}
                onClick={setSelectedQuest}
                onAdvance={handleAdvanceStatus}
              />
            ))}
          </SimpleGrid>
        ))}

      {/* Detail modal */}
      <QuestDetailModal
        quest={selectedQuest}
        onClose={() => setSelectedQuest(null)}
        onStart={handleStartQuest}
      />

      {/* Reset confirmation modal */}
      <Modal
        opened={resetModalOpen}
        onClose={() => setResetModalOpen(false)}
        title="Reset All Quests"
        centered
      >
        <Stack gap="md">
          <Text size="sm">
            This will reset <strong>all quests</strong> to pending status, clear all progress, and
            remove all member assignments. This action cannot be undone.
          </Text>
          <Text size="sm" c="dimmed">
            Are you sure you want to continue?
          </Text>
          <Group justify="flex-end" gap="sm">
            <Button variant="default" onClick={() => setResetModalOpen(false)} disabled={resetting}>
              Cancel
            </Button>
            <Button color="red" onClick={handleReset} loading={resetting}>
              Reset All Quests
            </Button>
          </Group>
        </Stack>
      </Modal>
    </Container>
  );
}
