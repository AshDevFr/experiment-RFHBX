import { Badge, Divider, Group, Loader, Modal, SimpleGrid, Stack, Text } from '@mantine/core';
import { useArtifacts } from '../hooks/useArtifacts';
import type { Character } from '../schemas/character';
import { STATUS_COLORS, STATUS_LABELS } from './CharacterCard';

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
  const { artifacts, isLoading: artifactsLoading } = useArtifacts(character?.id);

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
            <Badge variant="light" color={STATUS_COLORS[character.status] ?? 'gray'}>
              {STATUS_LABELS[character.status] ?? character.status.toUpperCase()}
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

        <Divider />

        <Stack gap="xs">
          <Text fw={600} size="sm">
            Artifacts
          </Text>
          {artifactsLoading ? (
            <Loader size="sm" data-testid="artifacts-loader" />
          ) : artifacts.length === 0 ? (
            <Text size="sm" c="dimmed" data-testid="no-artifacts-message">
              No artifacts yet.
            </Text>
          ) : (
            <Stack gap={4} data-testid="artifacts-list">
              {artifacts.map((artifact) => (
                <Group key={artifact.id} justify="space-between" align="center">
                  <Text size="sm" fw={500}>
                    {artifact.name}
                  </Text>
                  <Group gap={4}>
                    {artifact.stat_bonus &&
                      Object.entries(artifact.stat_bonus).map(([stat, value]) => (
                        <Badge
                          key={stat}
                          size="xs"
                          variant="outline"
                          color="green"
                          data-testid={`stat-bonus-${stat}`}
                        >
                          +{value} {stat}
                        </Badge>
                      ))}
                  </Group>
                </Group>
              ))}
            </Stack>
          )}
        </Stack>
      </Stack>
    </Modal>
  );
}
