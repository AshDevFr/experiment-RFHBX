import { Badge, Button, Divider, Group, Modal, Progress, Stack, Text } from '@mantine/core';
import type { Quest } from '../schemas/quest';

interface QuestDetailModalProps {
  quest: Quest | null;
  onClose: () => void;
  onStart?: (questId: number) => void;
}

const STATUS_COLORS: Record<string, string> = {
  pending: 'gray',
  active: 'blue',
  completed: 'green',
  failed: 'red',
};

function StatItem({ label, value }: { label: string; value: string | number }) {
  return (
    <Stack gap={2} align="center">
      <Text fw={700} size="lg">
        {value}
      </Text>
      <Text size="xs" c="dimmed" tt="uppercase">
        {label}
      </Text>
    </Stack>
  );
}

export function QuestDetailModal({ quest, onClose, onStart }: QuestDetailModalProps) {
  if (!quest) return null;

  const statusColor = STATUS_COLORS[quest.status] ?? 'gray';

  return (
    <Modal
      opened={quest !== null}
      onClose={onClose}
      title={
        <Text fw={700} size="lg">
          {quest.title}
        </Text>
      }
      size="lg"
      data-testid="quest-detail-modal"
    >
      <Stack gap="md">
        {quest.description && <Text size="sm">{quest.description}</Text>}

        <Group gap="xs">
          <Badge color={statusColor} variant="light">
            {quest.status}
          </Badge>
          <Badge variant="outline" color="violet">
            {quest.quest_type}
          </Badge>
          {quest.region && (
            <Badge variant="outline" color="teal">
              {quest.region}
            </Badge>
          )}
        </Group>

        <Divider />

        {/* Reward preview / quest stats */}
        <Group gap="xl" justify="center">
          <StatItem label="Danger" value={`${quest.danger_level}/10`} />
          {quest.success_chance != null && (
            <StatItem label="Success" value={`${quest.success_chance}%`} />
          )}
          <StatItem label="Attempts" value={quest.attempts} />
        </Group>

        {quest.progress != null && (
          <Stack gap={4}>
            <Text size="xs" c="dimmed">
              Progress
            </Text>
            <Progress value={quest.progress} size="md" color="blue" />
          </Stack>
        )}

        {quest.members !== undefined && (
          <>
            <Divider />
            <Text fw={600} size="sm">
              Members
            </Text>
            {quest.members.length === 0 ? (
              <Text size="sm" c="dimmed" data-testid="no-members-message">
                No members assigned to this quest.
              </Text>
            ) : (
              quest.members.map((m) => (
                <Group key={m.id} gap="xs">
                  <Text size="sm">{m.name}</Text>
                  <Badge size="xs" variant="outline" color="violet">
                    {m.race}
                  </Badge>
                  {m.level != null && (
                    <Badge size="xs" variant="outline" color="blue">
                      Lvl {m.level}
                    </Badge>
                  )}
                </Group>
              ))
            )}
          </>
        )}

        {quest.status === 'pending' && onStart && (
          <Button onClick={() => onStart(quest.id)} data-testid="start-quest-button">
            Start Quest
          </Button>
        )}
      </Stack>
    </Modal>
  );
}
