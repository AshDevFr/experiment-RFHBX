import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ReactNode } from 'react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import type { Quest } from '../schemas/quest';
import { QuestCard } from './QuestCard';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

const sampleQuest: Quest = {
  id: 1,
  title: 'Destroy the Ring',
  description: 'Journey to Mount Doom and destroy the One Ring.',
  status: 'pending',
  danger_level: 10,
  region: 'Mordor',
  progress: null,
  success_chance: 15,
  quest_type: 'campaign',
  campaign_order: 1,
  attempts: 0,
};

describe('QuestCard', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders quest title, status, danger level, and type', () => {
    render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Destroy the Ring')).toBeInTheDocument();
    expect(screen.getByText('pending')).toBeInTheDocument();
    expect(screen.getByText('Danger: 10')).toBeInTheDocument();
    expect(screen.getByText('campaign')).toBeInTheDocument();
  });

  it('renders the description', () => {
    render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText(/Journey to Mount Doom/)).toBeInTheDocument();
  });

  it('renders the region badge', () => {
    render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Mordor')).toBeInTheDocument();
  });

  it('calls onClick with the quest when clicked', async () => {
    const handleClick = vi.fn();
    render(<QuestCard quest={sampleQuest} onClick={handleClick} />, { wrapper });

    await userEvent.click(screen.getByTestId('quest-card'));
    expect(handleClick).toHaveBeenCalledWith(sampleQuest);
  });

  it('renders without description or region when absent', () => {
    const minimal: Quest = {
      id: 2,
      title: 'Quick Patrol',
      status: 'active',
      danger_level: 1,
      quest_type: 'random',
      attempts: 0,
    };
    render(<QuestCard quest={minimal} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByText('Quick Patrol')).toBeInTheDocument();
    expect(screen.getByText('active')).toBeInTheDocument();
    expect(screen.getByText('random')).toBeInTheDocument();
  });

  it('shows progress bar for active quests with progress', () => {
    const activeQuest: Quest = {
      ...sampleQuest,
      status: 'active',
      progress: 60,
    };
    render(<QuestCard quest={activeQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('does not show progress bar for pending quests', () => {
    render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
  });
});
