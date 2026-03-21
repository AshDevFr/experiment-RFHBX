import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// ---------------------------------------------------------------------------
// Mock the router hooks so we can render FellowshipPage without a real router.
// ---------------------------------------------------------------------------
const mockNavigate = vi.fn();
let mockSearchParams: { races?: string[]; realms?: string[] } = {};

vi.mock('@tanstack/react-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@tanstack/react-router')>();
  return {
    ...actual,
    createFileRoute: () => (opts: { component: unknown }) => opts,
    useNavigate: () => mockNavigate,
    useSearch: () => mockSearchParams,
  };
});

// ---------------------------------------------------------------------------
// Mock useCharacters so we control fetched data.
// ---------------------------------------------------------------------------
const mockUseCharacters = vi.fn();

vi.mock('../../hooks/useCharacters', () => ({
  useCharacters: () => mockUseCharacters(),
}));

// Import the page component AFTER mocks are registered.
import { FellowshipPage } from './fellowship';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

const sampleCharacters = [
  {
    id: 1,
    name: 'Frodo Baggins',
    race: 'Hobbit',
    realm: 'The Shire',
    title: 'Ring Bearer',
    status: 'idle',
  },
  {
    id: 2,
    name: 'Aragorn',
    race: 'Human',
    realm: 'Gondor',
    title: 'King Elessar',
    status: 'idle',
  },
  {
    id: 3,
    name: 'Legolas',
    race: 'Elf',
    realm: 'Woodland Realm',
    title: 'Prince of Mirkwood',
    status: 'idle',
  },
];

describe('FellowshipPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSearchParams = {};
  });

  afterEach(() => {
    cleanup();
  });

  it('renders character cards from the mocked API response', () => {
    mockUseCharacters.mockReturnValue({
      characters: sampleCharacters,
      isLoading: false,
      error: null,
    });

    render(<FellowshipPage />, { wrapper });

    expect(screen.getByText('Frodo Baggins')).toBeInTheDocument();
    expect(screen.getByText('Aragorn')).toBeInTheDocument();
    expect(screen.getByText('Legolas')).toBeInTheDocument();
    expect(screen.getAllByTestId('character-card')).toHaveLength(3);
  });

  it('shows skeleton loaders while fetching', () => {
    mockUseCharacters.mockReturnValue({
      characters: [],
      isLoading: true,
      error: null,
    });

    render(<FellowshipPage />, { wrapper });

    // No cards rendered during loading.
    expect(screen.queryByTestId('character-card')).not.toBeInTheDocument();
    // No error banner.
    expect(screen.queryByTestId('error-banner')).not.toBeInTheDocument();
  });

  it('renders an error banner when the API fails', () => {
    mockUseCharacters.mockReturnValue({
      characters: [],
      isLoading: false,
      error: 'Network Error',
    });

    render(<FellowshipPage />, { wrapper });

    expect(screen.getByTestId('error-banner')).toBeInTheDocument();
    expect(screen.getByText('Network Error')).toBeInTheDocument();
    // No cards on error.
    expect(screen.queryByTestId('character-card')).not.toBeInTheDocument();
  });

  it('filters characters by race when races search param is set', () => {
    mockSearchParams = { races: ['Hobbit'] };
    mockUseCharacters.mockReturnValue({
      characters: sampleCharacters,
      isLoading: false,
      error: null,
    });

    render(<FellowshipPage />, { wrapper });

    const cards = screen.getAllByTestId('character-card');
    expect(cards).toHaveLength(1);
    expect(screen.getByText('Frodo Baggins')).toBeInTheDocument();
    expect(screen.queryByText('Aragorn')).not.toBeInTheDocument();
    expect(screen.queryByText('Legolas')).not.toBeInTheDocument();
  });

  it('filters characters by realm when realms search param is set', () => {
    mockSearchParams = { realms: ['Gondor'] };
    mockUseCharacters.mockReturnValue({
      characters: sampleCharacters,
      isLoading: false,
      error: null,
    });

    render(<FellowshipPage />, { wrapper });

    const cards = screen.getAllByTestId('character-card');
    expect(cards).toHaveLength(1);
    expect(screen.getByText('Aragorn')).toBeInTheDocument();
    expect(screen.queryByText('Frodo Baggins')).not.toBeInTheDocument();
  });

  it('filters by both race and realm simultaneously', () => {
    mockSearchParams = { races: ['Human'], realms: ['Gondor'] };
    mockUseCharacters.mockReturnValue({
      characters: sampleCharacters,
      isLoading: false,
      error: null,
    });

    render(<FellowshipPage />, { wrapper });

    expect(screen.getAllByTestId('character-card')).toHaveLength(1);
    expect(screen.getByText('Aragorn')).toBeInTheDocument();
  });

  it('shows all characters when no filters are applied', () => {
    mockSearchParams = {};
    mockUseCharacters.mockReturnValue({
      characters: sampleCharacters,
      isLoading: false,
      error: null,
    });

    render(<FellowshipPage />, { wrapper });

    expect(screen.getAllByTestId('character-card')).toHaveLength(3);
  });

  it('shows a message when filters produce no results', () => {
    mockSearchParams = { races: ['Dragon'] };
    mockUseCharacters.mockReturnValue({
      characters: sampleCharacters,
      isLoading: false,
      error: null,
    });

    render(<FellowshipPage />, { wrapper });

    expect(screen.queryByTestId('character-card')).not.toBeInTheDocument();
    expect(screen.getByText(/No characters match/i)).toBeInTheDocument();
  });
});
