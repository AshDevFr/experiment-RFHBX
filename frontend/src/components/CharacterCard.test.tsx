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

  it('renders the character title', () => {
    render(<CharacterCard character={sampleCharacter} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Ring Bearer')).toBeInTheDocument();
  });

  it('renders the status badge', () => {
    render(<CharacterCard character={sampleCharacter} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('idle')).toBeInTheDocument();
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
});
