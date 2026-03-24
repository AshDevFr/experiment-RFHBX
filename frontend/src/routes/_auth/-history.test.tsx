import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// ---------------------------------------------------------------------------
// Mock router hooks — render HistoryPage without a real router
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
// Mock useQuestEventHistory so we control data
// ---------------------------------------------------------------------------
const mockUseQuestEventHistory = vi.fn();

vi.mock('../../hooks/useQuestEventHistory', () => ({
  useQuestEventHistory: () => mockUseQuestEventHistory(),
}));

// ---------------------------------------------------------------------------
// Import page AFTER mocks are registered
// ---------------------------------------------------------------------------
import { HistoryPage } from './history';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

const mockMeta = { total: 3, page: 1, per_page: 25, total_pages: 1 };

const mockSetEventTypes = vi.fn();
const mockSetQuestTitle = vi.fn();
const mockSetPage = vi.fn();

const baseHookValue = {
  events: [],
  meta: mockMeta,
  isLoading: false,
  error: null,
  filters: { eventTypes: [], questTitle: '', page: 1, perPage: 25 },
  setEventTypes: mockSetEventTypes,
  setQuestTitle: mockSetQuestTitle,
  setPage: mockSetPage,
};

const sampleEvents = [
  {
    id: 1,
    quest_id: 10,
    quest_title: 'Destroy the One Ring',
    event_type: 'started' as const,
    message: 'The quest has begun.',
    data: {},
    created_at: '2026-03-01T10:00:00.000Z',
  },
  {
    id: 2,
    quest_id: 10,
    quest_title: 'Destroy the One Ring',
    event_type: 'progress' as const,
    message: 'The fellowship advances.',
    data: { progress: 0.5 },
    created_at: '2026-03-01T11:00:00.000Z',
  },
  {
    id: 3,
    quest_id: 11,
    quest_title: 'Scout the Shire',
    event_type: 'completed' as const,
    message: null,
    data: {},
    created_at: '2026-03-01T12:00:00.000Z',
  },
];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('HistoryPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  describe('rendering', () => {
    it('renders the page title', () => {
      mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events: sampleEvents });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByText('EVENT HISTORY')).toBeInTheDocument();
    });

    it('renders event rows with timestamp, quest title, event type badge, and message', () => {
      mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events: sampleEvents });

      render(<HistoryPage />, { wrapper });

      expect(screen.getAllByTestId('event-row')).toHaveLength(3);

      // Quest titles
      expect(screen.getAllByText('Destroy the One Ring')).toHaveLength(2);
      expect(screen.getByText('Scout the Shire')).toBeInTheDocument();

      // Messages
      expect(screen.getByText('The quest has begun.')).toBeInTheDocument();
      expect(screen.getByText('The fellowship advances.')).toBeInTheDocument();
      // null message shows em dash
      expect(screen.getByText('—')).toBeInTheDocument();
    });

    it('renders event type badges with correct labels', () => {
      mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events: sampleEvents });

      render(<HistoryPage />, { wrapper });

      // Use within() to scope to badge elements, avoiding duplicate text in MultiSelect dropdown
      expect(within(screen.getByTestId('badge-started')).getByText('Started')).toBeInTheDocument();
      expect(within(screen.getByTestId('badge-progress')).getByText('Progress')).toBeInTheDocument();
      expect(
        within(screen.getByTestId('badge-completed')).getByText('Completed'),
      ).toBeInTheDocument();
    });

    it('renders the events table header columns', () => {
      mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events: [] });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByText('Timestamp')).toBeInTheDocument();
      expect(screen.getByText('Quest')).toBeInTheDocument();
      expect(screen.getByText('Type')).toBeInTheDocument();
      expect(screen.getByText('Message')).toBeInTheDocument();
    });

    it('shows the event count summary', () => {
      mockUseQuestEventHistory.mockReturnValue({
        ...baseHookValue,
        events: sampleEvents,
        meta: { total: 3, page: 1, per_page: 25, total_pages: 1 },
      });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByTestId('event-count')).toHaveTextContent('3 events');
    });
  });

  describe('loading state', () => {
    it('renders skeleton rows when loading', () => {
      mockUseQuestEventHistory.mockReturnValue({
        ...baseHookValue,
        isLoading: true,
        events: [],
        meta: null,
      });

      render(<HistoryPage />, { wrapper });

      expect(screen.queryByTestId('event-row')).not.toBeInTheDocument();
      expect(screen.queryByTestId('event-count')).not.toBeInTheDocument();
    });
  });

  describe('error state', () => {
    it('shows an error banner when the fetch fails', () => {
      mockUseQuestEventHistory.mockReturnValue({
        ...baseHookValue,
        error: 'Network Error',
        events: [],
      });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByTestId('error-banner')).toBeInTheDocument();
      expect(screen.getByText('Network Error')).toBeInTheDocument();
    });
  });

  describe('empty state', () => {
    it('shows empty state when no events match filters', () => {
      mockUseQuestEventHistory.mockReturnValue({
        ...baseHookValue,
        events: [],
        meta: { total: 0, page: 1, per_page: 25, total_pages: 1 },
      });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByTestId('empty-state')).toBeInTheDocument();
      expect(screen.getByText(/No events match/)).toBeInTheDocument();
    });
  });

  describe('filters', () => {
    it('renders the event type multi-select filter', () => {
      mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events: [] });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByTestId('event-type-filter')).toBeInTheDocument();
    });

    it('renders the quest title text input filter', () => {
      mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events: [] });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByTestId('quest-title-filter')).toBeInTheDocument();
    });

    it('updates quest title input value on change', async () => {
      mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events: [] });

      render(<HistoryPage />, { wrapper });

      const inputEl = screen.getByPlaceholderText('Search quest title…');
      await userEvent.type(inputEl, 'Ring');

      expect(inputEl).toHaveValue('Ring');
    });
  });

  describe('pagination', () => {
    it('shows pagination when total_pages > 1', () => {
      mockUseQuestEventHistory.mockReturnValue({
        ...baseHookValue,
        events: sampleEvents,
        meta: { total: 100, page: 1, per_page: 25, total_pages: 4 },
      });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByTestId('pagination')).toBeInTheDocument();
    });

    it('hides pagination when only one page', () => {
      mockUseQuestEventHistory.mockReturnValue({
        ...baseHookValue,
        events: sampleEvents,
        meta: { total: 3, page: 1, per_page: 25, total_pages: 1 },
      });

      render(<HistoryPage />, { wrapper });

      expect(screen.queryByTestId('pagination')).not.toBeInTheDocument();
    });

    it('shows multi-page summary in event count', () => {
      mockUseQuestEventHistory.mockReturnValue({
        ...baseHookValue,
        events: sampleEvents,
        meta: { total: 100, page: 2, per_page: 25, total_pages: 4 },
        filters: { ...baseHookValue.filters, page: 2 },
      });

      render(<HistoryPage />, { wrapper });

      expect(screen.getByTestId('event-count')).toHaveTextContent('page 2 of 4');
    });
  });

  describe('event type badge colours', () => {
    const colourCases: Array<{ type: string; label: string }> = [
      { type: 'started', label: 'Started' },
      { type: 'progress', label: 'Progress' },
      { type: 'completed', label: 'Completed' },
      { type: 'failed', label: 'Failed' },
      { type: 'restarted', label: 'Restarted' },
    ];

    for (const { type, label } of colourCases) {
      it(`renders a badge with label "${label}" for event_type "${type}"`, () => {
        const events = [
          {
            id: 99,
            quest_id: 1,
            quest_title: 'Test Quest',
            event_type: type as never,
            message: 'test',
            data: {},
            created_at: '2026-01-01T00:00:00.000Z',
          },
        ];
        mockUseQuestEventHistory.mockReturnValue({ ...baseHookValue, events });

        render(<HistoryPage />, { wrapper });

        const badge = screen.getByTestId(`badge-${type}`);
        expect(badge).toBeInTheDocument();
        // Scope text check to badge element to avoid MultiSelect dropdown duplicates
        expect(within(badge).getByText(label)).toBeInTheDocument();

        cleanup();
      });
    }
  });
});
