import { Badge, Divider, Group, Modal, SimpleGrid, Stack, Text } from '@mantine/core';
import type { Character } from '../schemas/character';

interface CharacterDetailModalProps {
  character: Character | null;
  onClose: () => void;
}

function StatItem({ label, value }: { label: string; value: number | undefined }) {
  if (value === undefined) return null;
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

export function CharacterDetailModal({ character, onClose }: CharacterDetailModalProps) {
  if (!character) return null;

  return (
    <Modal
      opened={character !== null}
      onClose={onClose}
      title={
        <Text fw={700} size="lg">
          {character.name}
        </Text>
      }
      size="md"
    >
      <Stack gap="md">
        {character.title && (
          <Text size="sm" c="dimmed" fs="italic">
            {character.title}
          </Text>
        )}

        <Group gap="xs">
          <Badge variant="outline" color="violet">
            {character.race}
          </Badge>
          {character.realm && (
            <Badge variant="outline" color="teal">
              {character.realm}
            </Badge>
          )}
          {character.status && (
            <Badge variant="light" color="gray">
              {character.status}
            </Badge>
          )}
          {character.ring_bearer && (
            <Badge variant="filled" color="yellow">
              Ring Bearer
            </Badge>
          )}
        </Group>

        <Divider />

        <SimpleGrid cols={3}>
          <StatItem label="Strength" value={character.strength} />
          <StatItem label="Wisdom" value={character.wisdom} />
          <StatItem label="Endurance" value={character.endurance} />
        </SimpleGrid>

        {(character.level !== undefined || character.xp !== undefined) && (
          <>
            <Divider />
            <Group gap="xl">
              {character.level !== undefined && (
                <Text size="sm">
                  <Text span fw={600}>
                    Level:{' '}
                  </Text>
                  {character.level}
                </Text>
              )}
              {character.xp !== undefined && (
                <Text size="sm">
                  <Text span fw={600}>
                    XP:{' '}
                  </Text>
                  {character.xp}
                </Text>
              )}
            </Group>
          </>
        )}
      </Stack>
    </Modal>
  );
}
