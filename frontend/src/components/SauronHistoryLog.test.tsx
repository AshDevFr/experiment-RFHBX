import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, describe, expect, it } from 'vitest';
import type { SauronGaze } from '../hooks/useSauronGazeChannel';
import { SauronHistoryLog } from './SauronHistoryLog';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

const sampleEvents: SauronGaze[] = [
  {
    region: 'Mordor',
    threat_level: 9,
    message: 'The Eye burns with fury',
    watched_at: '2026-03-21T14:05:00Z',
  },
  {
    region: 'The Shire',
    threat_level: 2,
    message: 'A gentle gaze drifts over the land',
    watched_at: '2026-03-21T14:00:00Z',
  },
  {
    region: 'Isengard',
    threat_level: 6,
    message: 'Saruman watches from his tower',
    watched_at: '2026-03-21T13:55:00Z',
  },
];

describe('SauronHistoryLog', () => {
  afterEach(() => {
    cleanup();
  });

  it('shows empty state when no events', () => {
    render(<SauronHistoryLog events={[]} />, { wrapper });

    expect(screen.getByTestId('history-empty')).toBeInTheDocument();
    expect(screen.getByText(/No events received/)).toBeInTheDocument();
  });

  it('renders all provided events', () => {
    render(<SauronHistoryLog events={sampleEvents} />, { wrapper });

    expect(screen.getAllByTestId('history-entry')).toHaveLength(3);
  });

  it('displays region and message for each entry', () => {
    render(<SauronHistoryLog events={sampleEvents} />, { wrapper });

    expect(screen.getByText('Mordor')).toBeInTheDocument();
    expect(screen.getByText('The Shire')).toBeInTheDocument();
    expect(screen.getByText('Isengard')).toBeInTheDocument();
    expect(screen.getByText('The Eye burns with fury')).toBeInTheDocument();
  });

  it('renders the scrollable history log container', () => {
    render(<SauronHistoryLog events={sampleEvents} />, { wrapper });

    expect(screen.getByTestId('history-log')).toBeInTheDocument();
  });

  it('shows newest entry first (first item in array)', () => {
    render(<SauronHistoryLog events={sampleEvents} />, { wrapper });

    const entries = screen.getAllByTestId('history-entry');
    expect(entries[0]).toHaveTextContent('Mordor');
    expect(entries[2]).toHaveTextContent('Isengard');
  });
});
