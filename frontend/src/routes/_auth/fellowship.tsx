import {
  Alert,
  Container,
  Group,
  MultiSelect,
  SimpleGrid,
  Skeleton,
  Stack,
  Text,
  Title,
} from '@mantine/core';
import { createFileRoute, useNavigate, useSearch } from '@tanstack/react-router';
import { useEffect, useMemo, useState } from 'react';
import { z } from 'zod';
import { CharacterCard } from '../../components/CharacterCard';
import { CharacterDetailModal } from '../../components/CharacterDetailModal';
import { useCharacters } from '../../hooks/useCharacters';
import { useQuestEventsChannel } from '../../hooks/useQuestEventsChannel';
import type { Character } from '../../schemas/character';

// ---------------------------------------------------------------------------
// Search (query) param schema for this route
// ---------------------------------------------------------------------------
const fellowshipSearchSchema = z.object({
  races: z.array(z.string()).optional(),
  realms: z.array(z.string()).optional(),
});

type FellowshipSearch = z.infer<typeof fellowshipSearchSchema>;

export const Route = createFileRoute('/_auth/fellowship')({
  validateSearch: (search: Record<string, unknown>): FellowshipSearch => {
    const result = fellowshipSearchSchema.safeParse(search);
    return result.success ? result.data : {};
  },
  component: FellowshipPage,
});

// ---------------------------------------------------------------------------
// Skeleton placeholder while loading
// ---------------------------------------------------------------------------
function CharacterGridSkeleton() {
  return (
    <SimpleGrid cols={{ base: 1, sm: 2, md: 3 }} spacing="md">
      {Array.from({ length: 9 }).map((_, i) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: skeleton placeholders have no identity
        <Skeleton key={i} height={110} radius="md" />
      ))}
    </SimpleGrid>
  );
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------
export function FellowshipPage() {
  const navigate = useNavigate({ from: Route.fullPath });
  const { races: selectedRaces = [], realms: selectedRealms = [] } = useSearch({
    from: '/_auth/fellowship',
  });

  const { characters, isLoading, error } = useCharacters();
  const [liveCharacters, setLiveCharacters] = useState<Character[]>([]);
  const [selectedCharacter, setSelectedCharacter] = useState<Character | null>(null);

  // Seed liveCharacters from the initial REST fetch.
  useEffect(() => {
    if (!isLoading && characters.length > 0) {
      setLiveCharacters(characters);
    }
  }, [characters, isLoading]);

  // Subscribe to global quest events and apply level_up patches in real time.
  // When a level_up event arrives its `data` payload contains character_id and
  // new_level, so we can update the matching character without a full refetch.
  const { latestEvent } = useQuestEventsChannel();
  useEffect(() => {
    if (!latestEvent) return;
    if ((latestEvent as { event_type?: string }).event_type !== 'level_up') return;

    const data = (latestEvent as { data?: { character_id?: number; new_level?: number } }).data;
    if (!data?.character_id || data.new_level == null) return;

    const { character_id, new_level } = data;

    const applyPatch = (c: Character): Character =>
      c.id === character_id ? { ...c, level: new_level } : c;

    setLiveCharacters((prev) => prev.map(applyPatch));
    setSelectedCharacter((prev) => (prev ? applyPatch(prev) : null));
  }, [latestEvent]);

  // Build filter options from the full character list.
  const raceOptions = useMemo(
    () =>
      [...new Set(liveCharacters.map((c) => c.race))].sort().map((r) => ({ value: r, label: r })),
    [liveCharacters],
  );

  const realmOptions = useMemo(
    () =>
      [...new Set(liveCharacters.map((c) => c.realm).filter((r): r is string => Boolean(r)))]
        .sort()
        .map((r) => ({ value: r, label: r })),
    [liveCharacters],
  );

  // Client-side filtering.
  const filtered = useMemo(
    () =>
      liveCharacters.filter((c) => {
        const raceMatch = selectedRaces.length === 0 || selectedRaces.includes(c.race);
        const realmMatch =
          selectedRealms.length === 0 || (c.realm != null && selectedRealms.includes(c.realm));
        return raceMatch && realmMatch;
      }),
    [liveCharacters, selectedRaces, selectedRealms],
  );

  function handleRaceChange(values: string[]) {
    navigate({
      search: (prev: FellowshipSearch) => ({ ...prev, races: values.length ? values : undefined }),
    });
  }

  function handleRealmChange(values: string[]) {
    navigate({
      search: (prev: FellowshipSearch) => ({ ...prev, realms: values.length ? values : undefined }),
    });
  }

  return (
    <Container size="xl">
      <Title order={2} mb="md">
        FELLOWSHIP
      </Title>

      {/* Error banner */}
      {error && (
        <Alert color="red" title="Failed to load characters" mb="md" data-testid="error-banner">
          {error}
        </Alert>
      )}

      {/* Filter controls */}
      <Group mb="lg" align="flex-end">
        <MultiSelect
          label="Filter by Race"
          placeholder="All races"
          data={raceOptions}
          value={selectedRaces}
          onChange={handleRaceChange}
          clearable
          searchable
          style={{ minWidth: 200 }}
          aria-label="Filter by race"
        />
        <MultiSelect
          label="Filter by Realm"
          placeholder="All realms"
          data={realmOptions}
          value={selectedRealms}
          onChange={handleRealmChange}
          clearable
          searchable
          style={{ minWidth: 200 }}
          aria-label="Filter by realm"
        />
      </Group>

      {/* Loading state */}
      {isLoading && <CharacterGridSkeleton />}

      {/* Character grid */}
      {!isLoading &&
        !error &&
        (filtered.length === 0 ? (
          <Stack align="center" mt="xl">
            <Text c="dimmed" size="sm">
              No characters match the selected filters.
            </Text>
          </Stack>
        ) : (
          <SimpleGrid cols={{ base: 1, sm: 2, md: 3 }} spacing="md">
            {filtered.map((character) => (
              <CharacterCard
                key={character.id}
                character={character}
                onClick={setSelectedCharacter}
              />
            ))}
          </SimpleGrid>
        ))}

      {/* Detail modal */}
      <CharacterDetailModal
        character={selectedCharacter}
        onClose={() => setSelectedCharacter(null)}
      />
    </Container>
  );
}
