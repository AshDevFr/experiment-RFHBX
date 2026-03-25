import { Badge, Card, Group, Stack, Text } from '@mantine/core';
import type { Character } from '../schemas/character';

interface CharacterCardProps {
  character: Character;
  onClick: (character: Character) => void;
}

export const STATUS_COLORS: Record<string, string> = {
  idle: 'gray',
  on_quest: 'blue',
  fallen: 'red',
};

export const STATUS_LABELS: Record<string, string> = {
  idle: 'IDLE',
  on_quest: 'ON QUEST',
  fallen: 'FALLEN',
};

export function CharacterCard({ character, onClick }: CharacterCardProps) {
  const statusColor = STATUS_COLORS[character.status ?? 'idle'] ?? 'gray';
  const statusLabel = character.status
    ? (STATUS_LABELS[character.status] ?? character.status.toUpperCase())
    : undefined;

  return (
    <Card
      shadow="sm"
      padding="md"
      radius="md"
      withBorder
      style={{ cursor: 'pointer' }}
      onClick={() => onClick(character)}
      data-testid="character-card"
    >
      <Stack gap="xs">
        <Group justify="space-between" align="flex-start">
          <Text fw={700} size="md" style={{ flex: 1 }}>
            {character.name}
          </Text>
          {statusLabel && (
            <Badge color={statusColor} size="sm" variant="light">
              {statusLabel}
            </Badge>
          )}
        </Group>

        {(character.level !== undefined || character.title) && (
          <Text size="sm" c="dimmed" fs="italic">
            {character.level !== undefined
              ? `Lv.${character.level}${character.title ? ' \u00b7 ' + character.title : ''}`
              : character.title}
          </Text>
        )}

        <Group gap="xs">
          <Badge size="sm" variant="outline" color="violet">
            {character.race}
          </Badge>
          {character.realm && (
            <Badge size="sm" variant="outline" color="teal">
              {character.realm}
            </Badge>
          )}
        </Group>
      </Stack>
    </Card>
  );
}
