import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ReactNode } from 'react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import type { Quest } from '../schemas/quest';
import { QuestDetailModal } from './QuestDetailModal';

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
  members: [
    { id: 1, name: 'Frodo Baggins', race: 'Hobbit', level: 3, status: 'idle' },
    { id: 2, name: 'Aragorn', race: 'Human', level: 10, status: 'idle' },
  ],
};

describe('QuestDetailModal', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders nothing when quest is null', () => {
    const { container } = render(
      <QuestDetailModal quest={null} onClose={vi.fn()} />,
      { wrapper },
    );

    expect(container.innerHTML).toBe('');
  });

  it('renders quest details when quest is provided', () => {
    render(
      <QuestDetailModal quest={sampleQuest} onClose={vi.fn()} />,
      { wrapper },
    );

    expect(screen.getByText('Destroy the Ring')).toBeInTheDocument();
    expect(screen.getByText(/Journey to Mount Doom/)).toBeInTheDocument();
    expect(screen.getByText('pending')).toBeInTheDocument();
    expect(screen.getByText('campaign')).toBeInTheDocument();
    expect(screen.getByText('Mordor')).toBeInTheDocument();
    expect(screen.getByText('10/10')).toBeInTheDocument();
    expect(screen.getByText('15%')).toBeInTheDocument();
  });

  it('renders member list', () => {
    render(
      <QuestDetailModal quest={sampleQuest} onClose={vi.fn()} />,
      { wrapper },
    );

    expect(screen.getByText('Frodo Baggins')).toBeInTheDocument();
    expect(screen.getByText('Aragorn')).toBeInTheDocument();
    expect(screen.getByText('Hobbit')).toBeInTheDocument();
    expect(screen.getByText('Human')).toBeInTheDocument();
  });

  it('shows start button for pending quests', () => {
    const onStart = vi.fn();
    render(
      <QuestDetailModal quest={sampleQuest} onClose={vi.fn()} onStart={onStart} />,
      { wrapper },
    );

    expect(screen.getByTestId('start-quest-button')).toBeInTheDocument();
  });

  it('calls onStart with quest id when start button is clicked', async () => {
    const onStart = vi.fn();
    render(
      <QuestDetailModal quest={sampleQuest} onClose={vi.fn()} onStart={onStart} />,
      { wrapper },
    );

    await userEvent.click(screen.getByTestId('start-quest-button'));
    expect(onStart).toHaveBeenCalledWith(1);
  });

  it('hides start button for active quests', () => {
    const activeQuest: Quest = { ...sampleQuest, status: 'active' };
    render(
      <QuestDetailModal quest={activeQuest} onClose={vi.fn()} onStart={vi.fn()} />,
      { wrapper },
    );

    expect(screen.queryByTestId('start-quest-button')).not.toBeInTheDocument();
  });

  it('shows progress bar when progress is set', () => {
    const withProgress: Quest = { ...sampleQuest, status: 'active', progress: 75 };
    render(
      <QuestDetailModal quest={withProgress} onClose={vi.fn()} />,
      { wrapper },
    );

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });
});
