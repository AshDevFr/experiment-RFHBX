import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// ---------------------------------------------------------------------------
// Mock the router hooks so we can render SauronPage without a real router.
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
// Mock useSauronGazeChannel so we control channel data.
// ---------------------------------------------------------------------------
const mockUseSauronGazeChannel = vi.fn();

vi.mock('../../hooks/useSauronGazeChannel', () => ({
  useSauronGazeChannel: () => mockUseSauronGazeChannel(),
}));

// Import the page component AFTER mocks are registered.
import { SauronPage } from './sauron';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

const sampleGaze = {
  region: 'Mordor',
  threat_level: 8,
  message: 'The Eye of Sauron turns toward Mordor',
  watched_at: '2026-03-21T14:00:00Z',
};

describe('SauronPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('shows loading state while connecting with no data', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: null,
      connectionStatus: 'connecting',
    });

    render(<SauronPage />, { wrapper });

    expect(screen.getByTestId('loading-state')).toBeInTheDocument();
    expect(screen.getByText(/Awaiting signal/)).toBeInTheDocument();
  });

  it('shows empty state when connected but no broadcast received yet', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: null,
      connectionStatus: 'connected',
    });

    render(<SauronPage />, { wrapper });

    expect(screen.getByTestId('empty-state')).toBeInTheDocument();
    expect(screen.getByText(/No threat activity detected/)).toBeInTheDocument();
    expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument();
    expect(screen.queryByTestId('disconnect-banner')).not.toBeInTheDocument();
  });

  it('replaces empty state with threat indicator when a gaze arrives', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: sampleGaze,
      connectionStatus: 'connected',
    });

    render(<SauronPage />, { wrapper });

    expect(screen.getByTestId('threat-indicator')).toBeInTheDocument();
    expect(screen.getByTestId('threat-level-value')).toHaveTextContent('8');
    expect(screen.getByTestId('threat-region')).toHaveTextContent('Mordor');
    expect(screen.getByTestId('threat-message')).toHaveTextContent(
      'The Eye of Sauron turns toward Mordor',
    );
  });

  it('shows disconnect banner when WebSocket is disconnected', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: null,
      connectionStatus: 'disconnected',
    });

    render(<SauronPage />, { wrapper });

    expect(screen.getByTestId('disconnect-banner')).toBeInTheDocument();
    expect(screen.getByText(/WebSocket connection lost/)).toBeInTheDocument();
  });

  it('does not show disconnect banner when connected', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: sampleGaze,
      connectionStatus: 'connected',
    });

    render(<SauronPage />, { wrapper });

    expect(screen.queryByTestId('disconnect-banner')).not.toBeInTheDocument();
  });

  it('shows cable status indicator', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: sampleGaze,
      connectionStatus: 'connected',
    });

    render(<SauronPage />, { wrapper });

    expect(screen.getByText('CABLE: CONNECTED')).toBeInTheDocument();
  });

  it('still shows last known state when disconnected', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: sampleGaze,
      connectionStatus: 'disconnected',
    });

    render(<SauronPage />, { wrapper });

    // Disconnect banner visible
    expect(screen.getByTestId('disconnect-banner')).toBeInTheDocument();
    // But threat data still rendered
    expect(screen.getByTestId('threat-indicator')).toBeInTheDocument();
    expect(screen.getByTestId('threat-level-value')).toHaveTextContent('8');
  });

  it('renders the history section heading when data is present', () => {
    mockUseSauronGazeChannel.mockReturnValue({
      latestGaze: sampleGaze,
      connectionStatus: 'connected',
    });

    render(<SauronPage />, { wrapper });

    expect(screen.getByText('History')).toBeInTheDocument();
  });
});
