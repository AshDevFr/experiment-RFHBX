import { MantineProvider } from '@mantine/core';
import { act, cleanup, render, screen } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// ---------------------------------------------------------------------------
// Mock the router hooks so we can render QuestsPage without a real router.
// ---------------------------------------------------------------------------
vi.mock('@tanstack/react-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@tanstack/react-router')>();
  return {
    ...actual,
    createFileRoute: () => (opts: { component: unknown }) => opts,
    useNavigate: () => vi.fn(),
    useSearch: () => ({}),
  };
});

// ---------------------------------------------------------------------------
// Mock useQuests so we control fetched data.
// ---------------------------------------------------------------------------
const mockRefetch = vi.fn();
const mockUseQuests = vi.fn();

vi.mock('../../hooks/useQuests', () => ({
  useQuests: () => mockUseQuests(),
}));

// ---------------------------------------------------------------------------
// Mock useQuestEventsChannel so we control live event data.
// ---------------------------------------------------------------------------
const mockUseQuestEventsChannel = vi.fn();

vi.mock('../../hooks/useQuestEventsChannel', () => ({
  useQuestEventsChannel: () => mockUseQuestEventsChannel(),
}));

// ---------------------------------------------------------------------------
// Mock the api module for quest actions.
// ---------------------------------------------------------------------------
vi.mock('../../lib/api', () => ({
  api: {
    patch: vi.fn(),
    post: vi.fn(),
  },
}));

// ---------------------------------------------------------------------------
// Mock mantine notifications.
// ---------------------------------------------------------------------------
vi.mock('@mantine/notifications', () => ({
  notifications: {
    show: vi.fn(),
  },
}));

// Import the page component AFTER mocks are registered.
import { QuestsPage } from './quests';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

const sampleQuests = [
  {
    id: 1,
    title: 'Destroy the Ring',
    description: 'Journey to Mount Doom.',
    status: 'pending',
    danger_level: 10,
    region: 'Mordor',
    progress: null,
    success_chance: 15,
    quest_type: 'campaign',
    campaign_order: 1,
    attempts: 0,
  },
  {
    id: 2,
    title: 'Scout the Shire',
    description: 'Patrol the borders.',
    status: 'active',
    danger_level: 2,
    region: 'The Shire',
    progress: 45,
    success_chance: 90,
    quest_type: 'random',
    campaign_order: null,
    attempts: 1,
  },
  {
    id: 3,
    title: 'Defend Helms Deep',
    description: null,
    status: 'completed',
    danger_level: 8,
    region: 'Rohan',
    progress: 100,
    success_chance: 60,
    quest_type: 'campaign',
    campaign_order: 2,
    attempts: 2,
  },
];

describe('QuestsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUseQuestEventsChannel.mockReturnValue({
      latestEvent: null,
      connectionStatus: 'connected',
    });
  });

  afterEach(() => {
    cleanup();
  });

  it('renders quest cards from the mocked API response', () => {
    mockUseQuests.mockReturnValue({
      quests: sampleQuests,
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByText('Destroy the Ring')).toBeInTheDocument();
    expect(screen.getByText('Scout the Shire')).toBeInTheDocument();
    expect(screen.getByText('Defend Helms Deep')).toBeInTheDocument();
    expect(screen.getAllByTestId('quest-card')).toHaveLength(3);
  });

  it('shows skeleton loaders while fetching', () => {
    mockUseQuests.mockReturnValue({
      quests: [],
      isLoading: true,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.queryByTestId('quest-card')).not.toBeInTheDocument();
    expect(screen.queryByTestId('error-banner')).not.toBeInTheDocument();
  });

  it('renders an error banner when the API fails', () => {
    mockUseQuests.mockReturnValue({
      quests: [],
      isLoading: false,
      error: 'Network Error',
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByTestId('error-banner')).toBeInTheDocument();
    expect(screen.getByText('Network Error')).toBeInTheDocument();
    expect(screen.queryByTestId('quest-card')).not.toBeInTheDocument();
  });

  it('shows disconnect banner when WebSocket is disconnected', () => {
    mockUseQuestEventsChannel.mockReturnValue({
      latestEvent: null,
      connectionStatus: 'disconnected',
    });
    mockUseQuests.mockReturnValue({
      quests: sampleQuests,
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByTestId('disconnect-banner')).toBeInTheDocument();
    expect(screen.getByText(/WebSocket connection lost/)).toBeInTheDocument();
  });

  it('does not show disconnect banner when connected', () => {
    mockUseQuests.mockReturnValue({
      quests: sampleQuests,
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.queryByTestId('disconnect-banner')).not.toBeInTheDocument();
  });

  it('shows cable status indicator', () => {
    mockUseQuests.mockReturnValue({
      quests: sampleQuests,
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByText('CABLE: CONNECTED')).toBeInTheDocument();
  });

  it('shows empty state when no quests match filter', () => {
    mockUseQuests.mockReturnValue({
      quests: [],
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByText(/No quests match/)).toBeInTheDocument();
  });

  it('renders management control buttons', () => {
    mockUseQuests.mockReturnValue({
      quests: sampleQuests,
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByText('Randomize Assignments')).toBeInTheDocument();
    expect(screen.getByText('Reset All Quests')).toBeInTheDocument();
  });

  it('renders advance buttons on pending and active quests', () => {
    mockUseQuests.mockReturnValue({
      quests: sampleQuests,
      isLoading: false,
      error: null,
      refetch: mockRefetch,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByText('Advance → Active')).toBeInTheDocument();
    expect(screen.getByText('Advance → Completed')).toBeInTheDocument();
  });

  // ---------------------------------------------------------------------------
  // Sort-order tests — verify sortQuests wiring in QuestsPage.
  //
  // The sort comparator uses the string 'active' (not 'in_progress') to identify
  // in-progress quests — matching the backend enum value and the Zod schema enum.
  // These tests confirm that wiring is correct end-to-end: the sortQuests helper
  // IS applied to the rendered list, and the status string comparison works.
  // ---------------------------------------------------------------------------
  describe('quest list sort order', () => {
    it('renders quests sorted on initial load: active first, others by campaign_order, completed last', () => {
      // sampleQuests arrives in the order the API returns (alphabetical by title):
      //   [Destroy the Ring / pending / order:1,
      //    Scout the Shire  / active  / no order,
      //    Defend Helms Deep / completed / order:2]
      // Expected sort result: Scout (active) → Destroy (pending, order:1) → Defend (completed)
      mockUseQuests.mockReturnValue({
        quests: sampleQuests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });

      render(<QuestsPage />, { wrapper });

      const cards = screen.getAllByTestId('quest-card');
      expect(cards).toHaveLength(3);
      // Active quest must be first — status 'active' drives priority 0 in sortQuests.
      expect(cards[0]).toHaveTextContent('Scout the Shire');
      // Pending quest with lowest campaign_order comes next.
      expect(cards[1]).toHaveTextContent('Destroy the Ring');
      // Completed quest is always last.
      expect(cards[2]).toHaveTextContent('Defend Helms Deep');
    });

    it('re-sorts after a started ActionCable event promotes a pending quest to active', () => {
      // Start with all three quests pending, arriving alphabetically from the API.
      const allPending = [
        { ...sampleQuests[2], id: 3, status: 'pending', campaign_order: 2 }, // Defend Helms Deep
        { ...sampleQuests[0], id: 1, status: 'pending', campaign_order: 1 }, // Destroy the Ring
        { ...sampleQuests[1], id: 2, status: 'pending', campaign_order: null }, // Scout the Shire
      ];
      mockUseQuests.mockReturnValue({
        quests: allPending,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: null,
        connectionStatus: 'connected',
      });

      const { rerender } = render(<QuestsPage />, { wrapper });

      // Before live update: all pending → sorted by campaign_order ascending.
      // null campaign_order (Scout) sorts after numbered ones.
      let cards = screen.getAllByTestId('quest-card');
      expect(cards[0]).toHaveTextContent('Destroy the Ring'); // order: 1
      expect(cards[1]).toHaveTextContent('Defend Helms Deep'); // order: 2
      expect(cards[2]).toHaveTextContent('Scout the Shire'); // order: null → last

      // Simulate a 'started' ActionCable event activating Scout the Shire (id: 2).
      // Status is set to 'active' — the exact string checked by sortQuests.
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: { event_type: 'started', quest_id: 2, data: {} },
        connectionStatus: 'connected',
      });

      act(() => {
        rerender(<QuestsPage />);
      });

      // After live update: Scout (now active) must float to position 0.
      cards = screen.getAllByTestId('quest-card');
      expect(cards[0]).toHaveTextContent('Scout the Shire'); // active → first
      expect(cards[1]).toHaveTextContent('Destroy the Ring'); // pending, order: 1
      expect(cards[2]).toHaveTextContent('Defend Helms Deep'); // pending, order: 2
    });
  });

  // ---------------------------------------------------------------------------
  // Live update tests — verify ActionCable event patches are applied correctly.
  // The broadcast payload shape from QuestEventBroadcaster is:
  //   { event_type, quest_id, quest_name, region, message, data, occurred_at }
  // Progress is nested in data.progress (0.0–1.0); status is derived from event_type.
  // ---------------------------------------------------------------------------
  describe('live updates via ActionCable', () => {
    it('updates quest progress from a progress event (data.progress)', () => {
      const quests = [{ ...sampleQuests[1], id: 2, status: 'active', progress: 0.3 }];
      mockUseQuests.mockReturnValue({
        quests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'progress',
          quest_id: 2,
          data: { progress: 0.75, increment: 0.05 },
        },
        connectionStatus: 'connected',
      });

      render(<QuestsPage />, { wrapper });

      const bar = screen.getByRole('progressbar');
      expect(bar).toHaveAttribute('aria-valuenow', '75');
    });

    it('updates quest status to completed from a completed event', () => {
      const quests = [{ ...sampleQuests[1], id: 2, status: 'active', progress: 0.9 }];
      mockUseQuests.mockReturnValue({
        quests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'completed',
          quest_id: 2,
          data: { xp_awarded: 200, result: 'success' },
        },
        connectionStatus: 'connected',
      });

      render(<QuestsPage />, { wrapper });

      expect(screen.getByText('completed')).toBeInTheDocument();
    });

    it('updates quest status to failed from a failed event', () => {
      const quests = [{ ...sampleQuests[1], id: 2, status: 'active', progress: 0.5 }];
      mockUseQuests.mockReturnValue({
        quests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'failed',
          quest_id: 2,
          data: { xp_awarded: 50, result: 'failure' },
        },
        connectionStatus: 'connected',
      });

      render(<QuestsPage />, { wrapper });

      expect(screen.getByText('failed')).toBeInTheDocument();
    });

    it('updates quest status to active and resets progress from a restarted event', () => {
      const quests = [{ ...sampleQuests[1], id: 2, status: 'failed', progress: 0.5 }];
      mockUseQuests.mockReturnValue({
        quests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'restarted',
          quest_id: 2,
          data: { attempt: 2 },
        },
        connectionStatus: 'connected',
      });

      render(<QuestsPage />, { wrapper });

      expect(screen.getByText('active')).toBeInTheDocument();
      const bar = screen.getByRole('progressbar');
      expect(bar).toHaveAttribute('aria-valuenow', '0');
    });

    it('updates quest status to active from a started event', () => {
      const quests = [{ ...sampleQuests[0], id: 1, status: 'pending', progress: null }];
      mockUseQuests.mockReturnValue({
        quests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'started',
          quest_id: 1,
          data: { party: ['Frodo', 'Sam'] },
        },
        connectionStatus: 'connected',
      });

      render(<QuestsPage />, { wrapper });

      expect(screen.getByText('active')).toBeInTheDocument();
    });

    it('does not patch quests when event has no matching quest_id', () => {
      mockUseQuests.mockReturnValue({
        quests: sampleQuests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'completed',
          quest_id: 9999,
          data: {},
        },
        connectionStatus: 'connected',
      });

      render(<QuestsPage />, { wrapper });

      // Original statuses remain untouched.
      expect(screen.getByText('pending')).toBeInTheDocument();
      expect(screen.getByText('active')).toBeInTheDocument();
    });

    it('ignores unknown event types without patching status', () => {
      const quests = [{ ...sampleQuests[1], id: 2, status: 'active', progress: 0.4 }];
      mockUseQuests.mockReturnValue({
        quests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'level_up',
          quest_id: 2,
          data: { character_name: 'Frodo', new_level: 5 },
        },
        connectionStatus: 'connected',
      });

      render(<QuestsPage />, { wrapper });

      // Status stays active — level_up events don't change quest status.
      expect(screen.getByText('active')).toBeInTheDocument();
    });

    it('updates quest progress reactively when latestEvent changes', () => {
      const quests = [{ ...sampleQuests[1], id: 2, status: 'active', progress: 0.2 }];
      mockUseQuests.mockReturnValue({
        quests,
        isLoading: false,
        error: null,
        refetch: mockRefetch,
      });
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: null,
        connectionStatus: 'connected',
      });

      const { rerender } = render(<QuestsPage />, { wrapper });

      // Quest progress bar reflects initial seeded value.
      let bar = screen.getByRole('progressbar');
      expect(bar).toHaveAttribute('aria-valuenow', '20');

      // Simulate receiving a live progress tick.
      mockUseQuestEventsChannel.mockReturnValue({
        latestEvent: {
          event_type: 'progress',
          quest_id: 2,
          data: { progress: 0.55, increment: 0.05 },
        },
        connectionStatus: 'connected',
      });

      act(() => {
        rerender(<QuestsPage />);
      });

      bar = screen.getByRole('progressbar');
      expect(bar).toHaveAttribute('aria-valuenow', '55');
    });
  });
});
