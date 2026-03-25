import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// ---------------------------------------------------------------------------
// Mock useQuestEventsChannel so we can inject synthetic events.
// ---------------------------------------------------------------------------
let mockLatestEvent: Record<string, unknown> | null = null;

vi.mock('../hooks/useQuestEventsChannel', () => ({
  useQuestEventsChannel: () => ({
    latestEvent: mockLatestEvent,
    connectionStatus: 'connected',
  }),
}));

import { act } from 'react';
import { QuestEventFeed } from './QuestEventFeed';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

describe('QuestEventFeed', () => {
  beforeEach(() => {
    mockLatestEvent = null;
  });

  afterEach(() => {
    cleanup();
  });

  it('renders the empty state when no events have arrived', () => {
    render(<QuestEventFeed />, { wrapper });
    expect(screen.getByTestId('quest-feed-empty')).toBeInTheDocument();
  });

  it('renders a quest event entry when an event arrives', async () => {
    const { rerender } = render(<QuestEventFeed />, { wrapper });

    mockLatestEvent = {
      event_type: 'completed',
      quest_id: 1,
      quest_name: 'The Road to Rivendell',
      message: 'Quest completed!',
      occurred_at: new Date().toISOString(),
    };

    await act(async () => {
      rerender(<QuestEventFeed />);
    });

    expect(screen.getByTestId('quest-event-feed')).toBeInTheDocument();
    expect(screen.getAllByTestId('quest-feed-entry')).toHaveLength(1);
    expect(screen.getByText('The Road to Rivendell')).toBeInTheDocument();
    expect(screen.getByText('Quest completed!')).toBeInTheDocument();
  });

  it('renders level_up events with a gold badge', async () => {
    const { rerender } = render(<QuestEventFeed />, { wrapper });

    mockLatestEvent = {
      event_type: 'level_up',
      quest_id: 2,
      quest_name: 'Patrol the Borders',
      message: 'Frodo Baggins reached level 2! Wisdom increased by 1.',
      occurred_at: new Date().toISOString(),
    };

    await act(async () => {
      rerender(<QuestEventFeed />);
    });

    expect(screen.getByTestId('badge-level_up')).toBeInTheDocument();
    expect(screen.getByText('Level Up')).toBeInTheDocument();
  });

  it('renders artifact_found events with the artifact_found badge', async () => {
    const { rerender } = render(<QuestEventFeed />, { wrapper });

    mockLatestEvent = {
      event_type: 'artifact_found',
      quest_id: 3,
      quest_name: 'Caves of Mirkwood',
      message: 'Aragorn found the Sword of Gondor!',
      occurred_at: new Date().toISOString(),
    };

    await act(async () => {
      rerender(<QuestEventFeed />);
    });

    expect(screen.getByTestId('badge-artifact_found')).toBeInTheDocument();
    expect(screen.getByText('Artifact Found')).toBeInTheDocument();
  });

  it('accumulates multiple events (newest first)', async () => {
    const { rerender } = render(<QuestEventFeed />, { wrapper });

    // First event
    mockLatestEvent = {
      event_type: 'started',
      quest_id: 1,
      quest_name: 'Quest One',
      message: 'Started!',
      occurred_at: new Date(Date.now() - 2000).toISOString(),
    };
    await act(async () => {
      rerender(<QuestEventFeed />);
    });

    // Second event (different reference)
    mockLatestEvent = {
      event_type: 'level_up',
      quest_id: 2,
      quest_name: 'Quest Two',
      message: 'Legolas reached level 3!',
      occurred_at: new Date().toISOString(),
    };
    await act(async () => {
      rerender(<QuestEventFeed />);
    });

    const entries = screen.getAllByTestId('quest-feed-entry');
    expect(entries).toHaveLength(2);
    // Newest (level_up) should be first
    expect(entries[0]).toHaveTextContent('Quest Two');
  });
});
