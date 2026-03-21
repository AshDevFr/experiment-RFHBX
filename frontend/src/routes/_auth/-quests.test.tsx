import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
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
// Mock the api module for start quest.
// ---------------------------------------------------------------------------
vi.mock('../../lib/api', () => ({
  api: {
    patch: vi.fn(),
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
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.queryByTestId('disconnect-banner')).not.toBeInTheDocument();
  });

  it('shows cable status indicator', () => {
    mockUseQuests.mockReturnValue({
      quests: sampleQuests,
      isLoading: false,
      error: null,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByText('CABLE: CONNECTED')).toBeInTheDocument();
  });

  it('shows empty state when no quests match filter', () => {
    mockUseQuests.mockReturnValue({
      quests: [],
      isLoading: false,
      error: null,
    });

    render(<QuestsPage />, { wrapper });

    expect(screen.getByText(/No quests match/)).toBeInTheDocument();
  });
});
