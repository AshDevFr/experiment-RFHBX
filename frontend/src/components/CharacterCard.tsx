import { Badge, Card, Group, Stack, Text } from '@mantine/core';
import type { Character } from '../schemas/character';

interface CharacterCardProps {
  character: Character;
  onClick: (character: Character) => void;
}

const STATUS_COLORS: Record<string, string> = {
  idle: 'gray',
  active: 'green',
  on_quest: 'blue',
  injured: 'orange',
  dead: 'red',
};

export function CharacterCard({ character, onClick }: CharacterCardProps) {
  const statusColor = STATUS_COLORS[character.status ?? 'idle'] ?? 'gray';

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
          {character.status && (
            <Badge color={statusColor} size="sm" variant="light">
              {character.status}
            </Badge>
          )}
        </Group>

        {character.title && (
          <Text size="xs" c="dimmed" fs="italic">
            {character.title}
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
