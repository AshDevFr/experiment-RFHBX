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

  it('renders nothing visible when quest is null', () => {
    render(<QuestDetailModal quest={null} onClose={vi.fn()} />, { wrapper });

    // Modal should not be present in the DOM.
    expect(screen.queryByText('Destroy the Ring')).not.toBeInTheDocument();
    expect(screen.queryByTestId('start-quest-button')).not.toBeInTheDocument();
  });

  it('renders quest details when quest is provided', () => {
    render(<QuestDetailModal quest={sampleQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByText('Destroy the Ring')).toBeInTheDocument();
    expect(screen.getByText(/Journey to Mount Doom/)).toBeInTheDocument();
    expect(screen.getByText('pending')).toBeInTheDocument();
    expect(screen.getByText('campaign')).toBeInTheDocument();
    expect(screen.getByText('Mordor')).toBeInTheDocument();
    expect(screen.getByText('10/10')).toBeInTheDocument();
    expect(screen.getByText('15%')).toBeInTheDocument();
  });

  it('renders member list', () => {
    render(<QuestDetailModal quest={sampleQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByText('Frodo Baggins')).toBeInTheDocument();
    expect(screen.getByText('Aragorn')).toBeInTheDocument();
    expect(screen.getByText('Hobbit')).toBeInTheDocument();
    expect(screen.getByText('Human')).toBeInTheDocument();
  });

  it('shows start button for pending quests', () => {
    const onStart = vi.fn();
    render(<QuestDetailModal quest={sampleQuest} onClose={vi.fn()} onStart={onStart} />, {
      wrapper,
    });

    expect(screen.getByTestId('start-quest-button')).toBeInTheDocument();
  });

  it('calls onStart with quest id when start button is clicked', async () => {
    const onStart = vi.fn();
    render(<QuestDetailModal quest={sampleQuest} onClose={vi.fn()} onStart={onStart} />, {
      wrapper,
    });

    await userEvent.click(screen.getByTestId('start-quest-button'));
    expect(onStart).toHaveBeenCalledWith(1);
  });

  it('hides start button for active quests', () => {
    const activeQuest: Quest = { ...sampleQuest, status: 'active' };
    render(<QuestDetailModal quest={activeQuest} onClose={vi.fn()} onStart={vi.fn()} />, {
      wrapper,
    });

    expect(screen.queryByTestId('start-quest-button')).not.toBeInTheDocument();
  });

  it('shows progress bar when progress is set', () => {
    const withProgress: Quest = { ...sampleQuest, status: 'active', progress: 0.75 };
    render(<QuestDetailModal quest={withProgress} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('shows empty state message when members array is present but empty', () => {
    const noMembers: Quest = { ...sampleQuest, members: [] };
    render(<QuestDetailModal quest={noMembers} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByTestId('no-members-message')).toBeInTheDocument();
    expect(screen.getByText('No members assigned to this quest.')).toBeInTheDocument();
  });

  it('hides the members section when members is undefined', () => {
    const noMembersField: Quest = { ...sampleQuest, members: undefined };
    render(<QuestDetailModal quest={noMembersField} onClose={vi.fn()} />, { wrapper });

    expect(screen.queryByTestId('no-members-message')).not.toBeInTheDocument();
    expect(screen.queryByText('Members')).not.toBeInTheDocument();
  });

  it('shows progress bar at 100% for completed quest with null progress', () => {
    const completedQuest: Quest = { ...sampleQuest, status: 'completed', progress: null };
    render(<QuestDetailModal quest={completedQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('shows progress bar at 100% for completed quest with stale zero progress', () => {
    const completedQuest: Quest = { ...sampleQuest, status: 'completed', progress: 0 };
    render(<QuestDetailModal quest={completedQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('does not show progress bar for pending quest with null progress', () => {
    render(<QuestDetailModal quest={sampleQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
  });

  it('active quest with progress 0.5 renders progress bar', () => {
    const activeQuest: Quest = { ...sampleQuest, status: 'active', progress: 0.5 };
    render(<QuestDetailModal quest={activeQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('active quest with progress 0.0 renders progress bar', () => {
    const activeQuest: Quest = { ...sampleQuest, status: 'active', progress: 0.0 };
    render(<QuestDetailModal quest={activeQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('completed quest renders progress bar at 100%', () => {
    const completedQuest: Quest = { ...sampleQuest, status: 'completed', progress: 0.37 };
    render(<QuestDetailModal quest={completedQuest} onClose={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('clamps progress to 100% when backend sends value > 1.0', () => {
    const overflowQuest: Quest = { ...sampleQuest, status: 'active', progress: 1.05 };
    render(<QuestDetailModal quest={overflowQuest} onClose={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-valuenow', '100');
  });
});
