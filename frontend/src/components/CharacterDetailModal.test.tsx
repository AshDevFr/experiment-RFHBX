import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen, waitFor } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { Character } from '../schemas/character';
import { CharacterDetailModal } from './CharacterDetailModal';

// Mock useArtifacts hook
vi.mock('../hooks/useArtifacts', () => ({
  useArtifacts: vi.fn(),
}));

import { useArtifacts } from '../hooks/useArtifacts';

const mockUseArtifacts = vi.mocked(useArtifacts);

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

describe('CharacterDetailModal', () => {
  beforeEach(() => {
    mockUseArtifacts.mockReturnValue({ artifacts: [], isLoading: false, error: null });
  });

  afterEach(() => {
    cleanup();
    vi.clearAllMocks();
  });

  it('renders nothing when character is null', () => {
    render(<CharacterDetailModal character={null} onClose={vi.fn()} />, {
      wrapper,
    });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('renders character name in the modal title', () => {
    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });
    expect(screen.getByText('Frodo Baggins')).toBeInTheDocument();
  });

  it('renders race and realm badges', () => {
    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });
    expect(screen.getByText('Hobbit')).toBeInTheDocument();
    expect(screen.getByText('The Shire')).toBeInTheDocument();
  });

  it('renders stats section', () => {
    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });
    expect(screen.getByText('Strength')).toBeInTheDocument();
    expect(screen.getByText('Wisdom')).toBeInTheDocument();
    expect(screen.getByText('Endurance')).toBeInTheDocument();
  });

  it('renders Ring Bearer badge when ring_bearer is true', () => {
    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });
    const badges = screen.getAllByText('Ring Bearer');
    expect(badges.length).toBeGreaterThanOrEqual(1);
    const ringBearerBadge = badges.find((el) => el.closest('.mantine-Badge-root'));
    expect(ringBearerBadge).toBeTruthy();
  });

  it('shows loading indicator while fetching artifacts', () => {
    mockUseArtifacts.mockReturnValue({ artifacts: [], isLoading: true, error: null });
    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });
    expect(screen.getByTestId('artifacts-loader')).toBeInTheDocument();
  });

  it('shows "No artifacts yet." when character has no artifacts', () => {
    mockUseArtifacts.mockReturnValue({ artifacts: [], isLoading: false, error: null });
    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });
    expect(screen.getByTestId('no-artifacts-message')).toBeInTheDocument();
    expect(screen.getByText('No artifacts yet.')).toBeInTheDocument();
  });

  it('renders artifact list with names and stat bonuses', async () => {
    mockUseArtifacts.mockReturnValue({
      artifacts: [
        { id: 1, name: 'Sting', artifact_type: 'sword', stat_bonus: { strength: 3 } },
        { id: 2, name: 'Mithril Shirt', artifact_type: 'armour', stat_bonus: { endurance: 5 } },
      ],
      isLoading: false,
      error: null,
    });

    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });

    await waitFor(() => {
      expect(screen.getByTestId('artifacts-list')).toBeInTheDocument();
    });

    expect(screen.getByText('Sting')).toBeInTheDocument();
    expect(screen.getByText('Mithril Shirt')).toBeInTheDocument();
    expect(screen.getByTestId('stat-bonus-strength')).toBeInTheDocument();
    expect(screen.getByText('+3 strength')).toBeInTheDocument();
    expect(screen.getByText('+5 endurance')).toBeInTheDocument();
  });

  it('calls useArtifacts with the character id', () => {
    render(<CharacterDetailModal character={sampleCharacter} onClose={vi.fn()} />, { wrapper });
    expect(mockUseArtifacts).toHaveBeenCalledWith(sampleCharacter.id);
  });

  it('calls useArtifacts with undefined when character is null', () => {
    render(<CharacterDetailModal character={null} onClose={vi.fn()} />, { wrapper });
    expect(mockUseArtifacts).toHaveBeenCalledWith(undefined);
  });
});
