import { Badge, Button, Card, Group, Progress, Stack, Text } from '@mantine/core';
import type { Quest } from '../schemas/quest';

interface QuestCardProps {
  quest: Quest;
  onClick: (quest: Quest) => void;
  onAdvance?: (quest: Quest) => void;
}

const STATUS_COLORS: Record<string, string> = {
  pending: 'gray',
  active: 'blue',
  completed: 'green',
  failed: 'red',
};

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

function dangerColor(level: number): string {
  if (level <= 3) return 'green';
  if (level <= 6) return 'yellow';
  return 'red';
}

export function QuestCard({ quest, onClick, onAdvance }: QuestCardProps) {
  const statusColor = STATUS_COLORS[quest.status] ?? 'gray';
  const nextStatus = STATUS_TRANSITIONS[quest.status];
  const effectiveProgress =
    quest.status === 'completed'
      ? 100
      : quest.progress != null
        ? Math.round(quest.progress * 100)
        : null;

  return (
    <Card
      shadow="sm"
      padding="md"
      radius="md"
      withBorder
      style={{ cursor: 'pointer' }}
      onClick={() => onClick(quest)}
      data-testid="quest-card"
    >
      <Stack gap="xs">
        <Group justify="space-between" align="flex-start">
          <Text fw={700} size="md" style={{ flex: 1 }}>
            {quest.title}
          </Text>
          <Badge color={statusColor} size="sm" variant="light">
            {quest.status}
          </Badge>
        </Group>

        {quest.description && (
          <Text size="xs" c="dimmed" lineClamp={2}>
            {quest.description}
          </Text>
        )}

        <Group gap="xs">
          <Badge size="sm" variant="outline" color={dangerColor(quest.danger_level)}>
            Danger: {quest.danger_level}
          </Badge>
          <Badge size="sm" variant="outline" color="violet">
            {quest.quest_type}
          </Badge>
          {quest.region && (
            <Badge size="sm" variant="outline" color="teal">
              {quest.region}
            </Badge>
          )}
        </Group>

        {effectiveProgress != null && (
          <Progress
            value={effectiveProgress}
            size="sm"
            color={STATUS_COLORS[quest.status] ?? 'gray'}
            aria-label={`Quest progress: ${Math.round(effectiveProgress)}%`}
            aria-valuenow={effectiveProgress}
            aria-valuemin={0}
            aria-valuemax={100}
          />
        )}

        {quest.members && quest.members.length > 0 && (
          <Group gap={4}>
            {quest.members.map((m) => (
              <Badge key={m.id} size="xs" variant="outline" color="gray">
                {m.name}
              </Badge>
            ))}
          </Group>
        )}

        {onAdvance && nextStatus && (
          <Button
            size="xs"
            variant="light"
            color={STATUS_COLORS[nextStatus] ?? 'blue'}
            onClick={(e) => {
              e.stopPropagation();
              onAdvance(quest);
            }}
            mt="xs"
          >
            Advance → {STATUS_LABELS[nextStatus] ?? nextStatus}
          </Button>
        )}
      </Stack>
    </Card>
  );
}
