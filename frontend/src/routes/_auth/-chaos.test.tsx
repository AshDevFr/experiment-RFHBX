import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// ---------------------------------------------------------------------------
// Mock router
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
// Mock useChaos hook
// ---------------------------------------------------------------------------
const mockWoundCharacter = vi.fn();
const mockFailQuest = vi.fn();
const mockSpikeThreat = vi.fn();
const mockStopSimulation = vi.fn();
const mockClearResult = vi.fn();

let mockResult: import('../../schemas/chaos').ChaosActionResult | null = null;
let mockError: string | null = null;
let mockIsLoading = false;

vi.mock('../../hooks/useChaos', () => ({
  useChaos: () => ({
    result: mockResult,
    error: mockError,
    isLoading: mockIsLoading,
    woundCharacter: mockWoundCharacter,
    failQuest: mockFailQuest,
    spikeThreat: mockSpikeThreat,
    stopSimulation: mockStopSimulation,
    clearResult: mockClearResult,
  }),
}));

// ---------------------------------------------------------------------------
// Mock @mantine/notifications (we test that show() is called conditionally)
// ---------------------------------------------------------------------------
const mockNotificationsShow = vi.fn();

vi.mock('@mantine/notifications', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@mantine/notifications')>();
  return {
    ...actual,
    notifications: {
      show: (...args: unknown[]) => mockNotificationsShow(...args),
    },
  };
});

// We need to import the default component for ChaosPage
// The file exports Route (with component), ChaosResultCard, ChaosActionCard
// The page function is the Route component
import * as ChaosModule from './chaos';
// Import AFTER mocks
import { ChaosActionCard, ChaosResultCard } from './chaos';

const ChaosPage = (ChaosModule.Route as { component: React.ComponentType }).component;

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

describe('ChaosResultCard', () => {
  afterEach(cleanup);

  it('renders wound_character result', () => {
    render(
      <ChaosResultCard
        result={{
          type: 'wound_character',
          result: { affected: { id: 1, name: 'Boromir', status: 'fallen', quest_id: null } },
        }}
      />,
      { wrapper },
    );

    expect(screen.getByText('CHAOS APPLIED')).toBeInTheDocument();
    expect(screen.getByText('Character wounded')).toBeInTheDocument();
    expect(screen.getByTestId('result-details')).toHaveTextContent('Boromir has fallen');
  });

  it('renders fail_quest result', () => {
    render(
      <ChaosResultCard
        result={{
          type: 'fail_quest',
          result: {
            affected: {
              id: 1,
              title: "Defend Helm's Deep",
              status: 'failed',
              progress: 0,
              members_reset: 3,
            },
          },
        }}
      />,
      { wrapper },
    );

    expect(screen.getByText('Quest failed')).toBeInTheDocument();
    expect(screen.getByTestId('result-details')).toHaveTextContent("Defend Helm's Deep");
    expect(screen.getByTestId('result-details')).toHaveTextContent('3 member(s)');
  });

  it('renders spike_threat result', () => {
    render(
      <ChaosResultCard
        result={{
          type: 'spike_threat',
          result: { affected: { region: 'Mordor', threat_level: 10, quest_id: 1 } },
        }}
      />,
      { wrapper },
    );

    expect(screen.getByText('Threat spiked')).toBeInTheDocument();
    expect(screen.getByTestId('result-details')).toHaveTextContent('Mordor');
    expect(screen.getByTestId('result-details')).toHaveTextContent('10');
  });

  it('renders stop_simulation result', () => {
    render(
      <ChaosResultCard
        result={{
          type: 'stop_simulation',
          result: {
            affected: {
              simulation_running: false,
              message: 'The Eye of Sauron loses focus — simulation halted.',
            },
          },
        }}
      />,
      { wrapper },
    );

    expect(screen.getByText('Simulation halted')).toBeInTheDocument();
    expect(screen.getByTestId('result-details')).toHaveTextContent('Eye of Sauron loses focus');
  });
});

describe('ChaosActionCard', () => {
  afterEach(cleanup);

  it('renders title, description, and button', () => {
    render(
      <ChaosActionCard
        title="Wound Character"
        description="Wound a random character."
        buttonLabel="Wound"
        buttonColor="red"
        testId="btn-wound"
        disabled={false}
        onClick={vi.fn()}
      />,
      { wrapper },
    );

    expect(screen.getByText('Wound Character')).toBeInTheDocument();
    expect(screen.getByText('Wound a random character.')).toBeInTheDocument();
    expect(screen.getByTestId('btn-wound')).toBeInTheDocument();
  });

  it('disables button when disabled is true', () => {
    render(
      <ChaosActionCard
        title="Wound Character"
        description="desc"
        buttonLabel="Wound"
        buttonColor="red"
        testId="btn-wound"
        disabled={true}
        onClick={vi.fn()}
      />,
      { wrapper },
    );

    expect(screen.getByTestId('btn-wound')).toBeDisabled();
  });

  it('calls onClick when button is clicked', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();

    render(
      <ChaosActionCard
        title="Wound Character"
        description="desc"
        buttonLabel="Wound"
        buttonColor="red"
        testId="btn-wound"
        disabled={false}
        onClick={onClick}
      />,
      { wrapper },
    );

    await user.click(screen.getByTestId('btn-wound'));
    expect(onClick).toHaveBeenCalledOnce();
  });
});

describe('ChaosPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockResult = null;
    mockError = null;
    mockIsLoading = false;
  });

  afterEach(cleanup);

  it('renders the page title', () => {
    render(<ChaosPage />, { wrapper });
    expect(screen.getByText('Chaos Panel')).toBeInTheDocument();
  });

  it('renders all 4 action buttons', () => {
    render(<ChaosPage />, { wrapper });
    expect(screen.getByTestId('btn-wound-character')).toBeInTheDocument();
    expect(screen.getByTestId('btn-fail-quest')).toBeInTheDocument();
    expect(screen.getByTestId('btn-spike-threat')).toBeInTheDocument();
    expect(screen.getByTestId('btn-stop-simulation')).toBeInTheDocument();
  });

  it('disables buttons when loading', () => {
    mockIsLoading = true;
    render(<ChaosPage />, { wrapper });

    expect(screen.getByTestId('btn-wound-character')).toBeDisabled();
    expect(screen.getByTestId('btn-fail-quest')).toBeDisabled();
    expect(screen.getByTestId('btn-spike-threat')).toBeDisabled();
    expect(screen.getByTestId('btn-stop-simulation')).toBeDisabled();
  });

  it('shows error alert when error is set', () => {
    mockError = 'Something went wrong';
    render(<ChaosPage />, { wrapper });
    expect(screen.getByTestId('error-alert')).toBeInTheDocument();
    expect(screen.getByText('Something went wrong')).toBeInTheDocument();
  });

  it('does not show error alert when no error', () => {
    render(<ChaosPage />, { wrapper });
    expect(screen.queryByTestId('error-alert')).not.toBeInTheDocument();
  });

  it('shows result card when result is set', () => {
    mockResult = {
      type: 'wound_character',
      result: { affected: { id: 1, name: 'Boromir', status: 'fallen', quest_id: null } },
    };
    render(<ChaosPage />, { wrapper });
    expect(screen.getByTestId('result-card')).toBeInTheDocument();
  });

  it('calls woundCharacter and shows notification on success', async () => {
    const user = userEvent.setup();
    mockWoundCharacter.mockResolvedValue(true);

    render(<ChaosPage />, { wrapper });
    await user.click(screen.getByTestId('btn-wound-character'));

    expect(mockWoundCharacter).toHaveBeenCalledOnce();
    expect(mockNotificationsShow).toHaveBeenCalledWith(
      expect.objectContaining({ title: 'Chaos injected' }),
    );
  });

  it('calls woundCharacter but does NOT show notification on failure', async () => {
    const user = userEvent.setup();
    mockWoundCharacter.mockResolvedValue(false);

    render(<ChaosPage />, { wrapper });
    await user.click(screen.getByTestId('btn-wound-character'));

    expect(mockWoundCharacter).toHaveBeenCalledOnce();
    expect(mockNotificationsShow).not.toHaveBeenCalled();
  });

  it('calls failQuest on button click', async () => {
    const user = userEvent.setup();
    mockFailQuest.mockResolvedValue(true);

    render(<ChaosPage />, { wrapper });
    await user.click(screen.getByTestId('btn-fail-quest'));

    expect(mockFailQuest).toHaveBeenCalledOnce();
    expect(mockNotificationsShow).toHaveBeenCalled();
  });

  it('calls spikeThreat on button click', async () => {
    const user = userEvent.setup();
    mockSpikeThreat.mockResolvedValue(true);

    render(<ChaosPage />, { wrapper });
    await user.click(screen.getByTestId('btn-spike-threat'));

    expect(mockSpikeThreat).toHaveBeenCalledOnce();
    expect(mockNotificationsShow).toHaveBeenCalled();
  });

  it('calls stopSimulation on button click', async () => {
    const user = userEvent.setup();
    mockStopSimulation.mockResolvedValue(true);

    render(<ChaosPage />, { wrapper });
    await user.click(screen.getByTestId('btn-stop-simulation'));

    expect(mockStopSimulation).toHaveBeenCalledOnce();
    expect(mockNotificationsShow).toHaveBeenCalled();
  });
});
