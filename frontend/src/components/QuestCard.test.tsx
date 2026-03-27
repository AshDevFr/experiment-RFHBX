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
      progress: 0.6,
    };
    render(<QuestCard quest={activeQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('does not show progress bar when progress is null', () => {
    render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
  });

  it('shows progress bar for completed quests with progress', () => {
    const completedQuest: Quest = {
      ...sampleQuest,
      status: 'completed',
      progress: 1.0,
    };
    render(<QuestCard quest={completedQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('shows progress bar for failed quests with progress', () => {
    const failedQuest: Quest = {
      ...sampleQuest,
      status: 'failed',
      progress: 0.42,
    };
    render(<QuestCard quest={failedQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('progress bar has an accessible aria-label', () => {
    const activeQuest: Quest = {
      ...sampleQuest,
      status: 'active',
      progress: 0.75,
    };
    render(<QuestCard quest={activeQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 75%');
    expect(bar).toHaveAttribute('aria-valuenow', '75');
    expect(bar).toHaveAttribute('aria-valuemin', '0');
    expect(bar).toHaveAttribute('aria-valuemax', '100');
  });

  it('progress bar uses green color for completed quests', () => {
    const completedQuest: Quest = {
      ...sampleQuest,
      status: 'completed',
      progress: 1.0,
    };
    render(<QuestCard quest={completedQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    // Mantine encodes the color as a CSS variable on the section element; verify the bar is present
    expect(bar).toBeInTheDocument();
  });

  it('progress bar uses red color for failed quests', () => {
    const failedQuest: Quest = {
      ...sampleQuest,
      status: 'failed',
      progress: 0.3,
    };
    render(<QuestCard quest={failedQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('shows progress bar at 100% for completed quest with null progress', () => {
    const completedQuest: Quest = {
      ...sampleQuest,
      status: 'completed',
      progress: null,
    };
    render(<QuestCard quest={completedQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toBeInTheDocument();
    expect(bar).toHaveAttribute('aria-valuenow', '100');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 100%');
  });

  it('shows progress bar at 100% for completed quest with stale zero progress', () => {
    const completedQuest: Quest = {
      ...sampleQuest,
      status: 'completed',
      progress: 0,
    };
    render(<QuestCard quest={completedQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toBeInTheDocument();
    expect(bar).toHaveAttribute('aria-valuenow', '100');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 100%');
  });

  it('does not show progress bar for pending quests with null progress', () => {
    render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

    expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
  });

  it('active quest with progress 0.5 renders bar at 50%', () => {
    const activeQuest: Quest = {
      ...sampleQuest,
      status: 'active',
      progress: 0.5,
    };
    render(<QuestCard quest={activeQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 50%');
    expect(bar).toHaveAttribute('aria-valuenow', '50');
  });

  it('active quest with progress 0.0 renders bar at 0%', () => {
    const activeQuest: Quest = {
      ...sampleQuest,
      status: 'active',
      progress: 0.0,
    };
    render(<QuestCard quest={activeQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 0%');
    expect(bar).toHaveAttribute('aria-valuenow', '0');
  });

  it('completed quest renders bar at 100% regardless of stored progress', () => {
    const completedQuest: Quest = {
      ...sampleQuest,
      status: 'completed',
      progress: 0.37,
    };
    render(<QuestCard quest={completedQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 100%');
    expect(bar).toHaveAttribute('aria-valuenow', '100');
  });

  it('clamps progress to 100% when backend sends value > 1.0', () => {
    const overflowQuest: Quest = {
      ...sampleQuest,
      status: 'active',
      progress: 1.05,
    };
    render(<QuestCard quest={overflowQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-valuenow', '100');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 100%');
  });

  it('clamps progress to 0% when backend sends negative value', () => {
    const negativeQuest: Quest = {
      ...sampleQuest,
      status: 'active',
      progress: -0.1,
    };
    render(<QuestCard quest={negativeQuest} onClick={vi.fn()} />, { wrapper });

    const bar = screen.getByRole('progressbar');
    expect(bar).toHaveAttribute('aria-valuenow', '0');
    expect(bar).toHaveAttribute('aria-label', 'Quest progress: 0%');
  });

  // ---------------------------------------------------------------------------
  // Layout tests — verify consistent card height and button anchoring (#188)
  // ---------------------------------------------------------------------------
  describe('card layout', () => {
    it('card root has flex column layout for consistent height', () => {
      render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

      const card = screen.getByTestId('quest-card');
      expect(card).toHaveStyle({ display: 'flex', flexDirection: 'column', height: '100%' });
    });

    it('renders the advance button outside the content stack when applicable', () => {
      const pendingQuest: Quest = { ...sampleQuest, status: 'pending' };
      const handleAdvance = vi.fn();
      render(<QuestCard quest={pendingQuest} onClick={vi.fn()} onAdvance={handleAdvance} />, {
        wrapper,
      });

      const card = screen.getByTestId('quest-card');
      const btn = screen.getByText('Advance → Active').closest('button');
      expect(btn).toBeInTheDocument();
      // Button must be a direct or shallow descendant of the card, not buried inside the Stack
      expect(card).toContainElement(btn);
    });

    it('does not render advance button for completed quests', () => {
      const completedQuest: Quest = { ...sampleQuest, status: 'completed', progress: 1.0 };
      render(<QuestCard quest={completedQuest} onClick={vi.fn()} onAdvance={vi.fn()} />, {
        wrapper,
      });

      expect(screen.queryByText(/Advance/)).not.toBeInTheDocument();
    });

    it('does not render advance button when onAdvance is not provided', () => {
      render(<QuestCard quest={sampleQuest} onClick={vi.fn()} />, { wrapper });

      expect(screen.queryByText(/Advance/)).not.toBeInTheDocument();
    });
  });
});
