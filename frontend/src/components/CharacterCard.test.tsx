import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ReactNode } from 'react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import type { Character } from '../schemas/character';
import { CharacterCard } from './CharacterCard';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

const sampleCharacter: Character = {
  id: 1,
  name: 'Frodo Baggins',
  race: 'Hobbit',
  realm: 'The Shire',
  title: 'Ring Bearer',
  ring_bearer: true,
  status: 'idle',
  strength: 5,
  wisdom: 14,
  endurance: 12,
  level: 1,
  xp: 0,
};

describe('CharacterCard', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders character name, race, and realm', () => {
    render(<CharacterCard character={sampleCharacter} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Frodo Baggins')).toBeInTheDocument();
    expect(screen.getByText('Hobbit')).toBeInTheDocument();
    expect(screen.getByText('The Shire')).toBeInTheDocument();
  });

  it('renders level and title together on the second line', () => {
    render(<CharacterCard character={sampleCharacter} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Lv.1 \u00b7 Ring Bearer')).toBeInTheDocument();
  });

  it('renders only the level prefix when character has no title', () => {
    const noTitle: Character = { id: 3, name: 'Sm\u00e9agol', race: 'Hobbit', level: 5 };
    render(<CharacterCard character={noTitle} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Lv.5')).toBeInTheDocument();
  });

  it('renders nothing on the second line when level and title are absent', () => {
    const minimal: Character = { id: 4, name: 'Unnamed Orc', race: 'Orc' };
    render(<CharacterCard character={minimal} onClick={vi.fn()} />, { wrapper });

    expect(screen.queryByText(/^Lv\./)).not.toBeInTheDocument();
  });

  it('renders the status badge with human-readable label for idle', () => {
    render(<CharacterCard character={sampleCharacter} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('IDLE')).toBeInTheDocument();
  });

  it('renders ON QUEST badge for on_quest status', () => {
    const onQuestChar: Character = { ...sampleCharacter, status: 'on_quest' };
    render(<CharacterCard character={onQuestChar} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('ON QUEST')).toBeInTheDocument();
  });

  it('renders FALLEN badge for fallen status', () => {
    const fallenChar: Character = { ...sampleCharacter, status: 'fallen' };
    render(<CharacterCard character={fallenChar} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('FALLEN')).toBeInTheDocument();
  });

  it('does not render a status badge when status is absent', () => {
    const noStatus: Character = { id: 5, name: 'Unknown Wanderer', race: 'Man' };
    render(<CharacterCard character={noStatus} onClick={vi.fn()} />, { wrapper });

    expect(screen.queryByText('IDLE')).not.toBeInTheDocument();
  });

  it('calls onClick with the character when clicked', async () => {
    const handleClick = vi.fn();
    render(<CharacterCard character={sampleCharacter} onClick={handleClick} />, { wrapper });

    await userEvent.click(screen.getByTestId('character-card'));
    expect(handleClick).toHaveBeenCalledWith(sampleCharacter);
  });

  it('renders without title or realm when absent', () => {
    const minimal: Character = { id: 2, name: 'Tom Bombadil', race: 'Unknown' };
    render(<CharacterCard character={minimal} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Tom Bombadil')).toBeInTheDocument();
    expect(screen.getByText('Unknown')).toBeInTheDocument();
  });

  it('shows artifact count badge when character has artifacts', () => {
    const withArtifacts: Character = { ...sampleCharacter, artifact_count: 3 };
    render(<CharacterCard character={withArtifacts} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByTestId('artifact-count-badge')).toBeInTheDocument();
    expect(screen.getByText('3 artifacts')).toBeInTheDocument();
  });

  it('shows singular "artifact" when count is 1', () => {
    const oneArtifact: Character = { ...sampleCharacter, artifact_count: 1 };
    render(<CharacterCard character={oneArtifact} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('1 artifact')).toBeInTheDocument();
  });

  it('does not show artifact badge when count is 0', () => {
    const noArtifacts: Character = { ...sampleCharacter, artifact_count: 0 };
    render(<CharacterCard character={noArtifacts} onClick={vi.fn()} />, { wrapper });

    expect(screen.queryByTestId('artifact-count-badge')).not.toBeInTheDocument();
  });

  it('does not show artifact badge when artifact_count is absent', () => {
    render(<CharacterCard character={sampleCharacter} onClick={vi.fn()} />, { wrapper });

    expect(screen.queryByTestId('artifact-count-badge')).not.toBeInTheDocument();
  });
});
