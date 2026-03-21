import { Badge, Card, Group, Progress, Stack, Text } from '@mantine/core';
import type { Quest } from '../schemas/quest';

interface QuestCardProps {
  quest: Quest;
  onClick: (quest: Quest) => void;
}

const STATUS_COLORS: Record<string, string> = {
  pending: 'gray',
  active: 'blue',
  completed: 'green',
  failed: 'red',
};

function dangerColor(level: number): string {
  if (level <= 3) return 'green';
  if (level <= 6) return 'yellow';
  return 'red';
}

export function QuestCard({ quest, onClick }: QuestCardProps) {
  const statusColor = STATUS_COLORS[quest.status] ?? 'gray';

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

        {quest.progress != null && quest.status === 'active' && (
          <Progress value={quest.progress} size="sm" color="blue" />
        )}
      </Stack>
    </Card>
  );
}
