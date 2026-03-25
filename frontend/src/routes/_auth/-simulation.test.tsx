import { MantineProvider } from '@mantine/core';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
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
// Mock useSimulation
// ---------------------------------------------------------------------------
const mockUseSimulation = vi.fn();
vi.mock('../../hooks/useSimulation', () => ({
  useSimulation: () => mockUseSimulation(),
}));

// ---------------------------------------------------------------------------
// Mock notifications
// ---------------------------------------------------------------------------
vi.mock('@mantine/notifications', () => ({
  notifications: { show: vi.fn() },
}));

// Import components AFTER mocks
import {
  SimulationConfigForm,
  SimulationPage,
  SimulationStatusPanel,
  validateConfigForm,
} from './simulation';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

const sampleConfig = {
  id: 1,
  mode: 'campaign' as const,
  running: false,
  tick_interval_seconds: 60,
  progress_min: 0.01,
  progress_max: 0.1,
  campaign_position: 0,
  tick_count: 42,
};

// ---------------------------------------------------------------------------
// validateConfigForm unit tests
// ---------------------------------------------------------------------------

describe('validateConfigForm', () => {
  it('returns no errors for valid values', () => {
    const errors = validateConfigForm({
      tick_interval_seconds: 60,
      progress_min: 0.01,
      progress_max: 0.1,
      mode: 'campaign',
    });
    expect(errors).toEqual({});
  });

  it('errors when tick_interval_seconds is 0', () => {
    const errors = validateConfigForm({
      tick_interval_seconds: 0,
      progress_min: 0.01,
      progress_max: 0.1,
      mode: 'campaign',
    });
    expect(errors.tick_interval_seconds).toBeTruthy();
  });

  it('errors when tick_interval_seconds is negative', () => {
    const errors = validateConfigForm({
      tick_interval_seconds: -5,
      progress_min: 0.01,
      progress_max: 0.1,
      mode: 'campaign',
    });
    expect(errors.tick_interval_seconds).toBeTruthy();
  });

  it('errors when progress_min >= progress_max', () => {
    const errors = validateConfigForm({
      tick_interval_seconds: 60,
      progress_min: 0.5,
      progress_max: 0.3,
      mode: 'campaign',
    });
    expect(errors.progress_min).toBeTruthy();
    expect(errors.progress_max).toBeTruthy();
  });

  it('errors when progress_min equals progress_max', () => {
    const errors = validateConfigForm({
      tick_interval_seconds: 60,
      progress_min: 0.1,
      progress_max: 0.1,
      mode: 'campaign',
    });
    expect(errors.progress_min).toBeTruthy();
  });

  it('errors when progress_min is below 0', () => {
    const errors = validateConfigForm({
      tick_interval_seconds: 60,
      progress_min: -0.1,
      progress_max: 0.1,
      mode: 'campaign',
    });
    expect(errors.progress_min).toBeTruthy();
  });

  it('errors when progress_max exceeds 1', () => {
    const errors = validateConfigForm({
      tick_interval_seconds: 60,
      progress_min: 0.1,
      progress_max: 1.5,
      mode: 'campaign',
    });
    expect(errors.progress_max).toBeTruthy();
  });
});

// ---------------------------------------------------------------------------
// SimulationStatusPanel
// ---------------------------------------------------------------------------

describe('SimulationStatusPanel', () => {
  afterEach(() => {
    cleanup();
  });

  it('shows STOPPED badge when not running', () => {
    render(
      <SimulationStatusPanel
        config={sampleConfig}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('status-badge')).toHaveTextContent('STOPPED');
  });

  it('shows RUNNING badge when running', () => {
    render(
      <SimulationStatusPanel
        config={{ ...sampleConfig, running: true }}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('status-badge')).toHaveTextContent('RUNNING');
  });

  it('disables Start button when already running', () => {
    render(
      <SimulationStatusPanel
        config={{ ...sampleConfig, running: true }}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('start-button')).toBeDisabled();
  });

  it('disables Stop button when not running', () => {
    render(
      <SimulationStatusPanel
        config={{ ...sampleConfig, running: false }}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('stop-button')).toBeDisabled();
  });

  it('enables Start button when stopped', () => {
    render(
      <SimulationStatusPanel
        config={{ ...sampleConfig, running: false }}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('start-button')).not.toBeDisabled();
  });

  it('enables Stop button when running', () => {
    render(
      <SimulationStatusPanel
        config={{ ...sampleConfig, running: true }}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('stop-button')).not.toBeDisabled();
  });

  it('disables both buttons while an action is in progress', () => {
    render(
      <SimulationStatusPanel
        config={sampleConfig}
        isActing={true}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('start-button')).toBeDisabled();
    expect(screen.getByTestId('stop-button')).toBeDisabled();
  });

  it('calls onStart when Start is clicked', async () => {
    const onStart = vi.fn();
    render(
      <SimulationStatusPanel
        config={sampleConfig}
        isActing={false}
        onStart={onStart}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    fireEvent.click(screen.getByTestId('start-button'));
    expect(onStart).toHaveBeenCalledTimes(1);
  });

  it('calls onStop when Stop is clicked', async () => {
    const onStop = vi.fn();
    render(
      <SimulationStatusPanel
        config={{ ...sampleConfig, running: true }}
        isActing={false}
        onStart={vi.fn()}
        onStop={onStop}
      />,
      { wrapper },
    );
    fireEvent.click(screen.getByTestId('stop-button'));
    expect(onStop).toHaveBeenCalledTimes(1);
  });

  it('displays tick count', () => {
    render(
      <SimulationStatusPanel
        config={{ ...sampleConfig, tick_count: 99 }}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('tick-count')).toHaveTextContent('99');
  });

  it('displays mode badge', () => {
    render(
      <SimulationStatusPanel
        config={sampleConfig}
        isActing={false}
        onStart={vi.fn()}
        onStop={vi.fn()}
      />,
      { wrapper },
    );
    expect(screen.getByTestId('mode-badge')).toHaveTextContent('campaign');
  });
});

// ---------------------------------------------------------------------------
// SimulationConfigForm
// ---------------------------------------------------------------------------

describe('SimulationConfigForm', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders save button', () => {
    render(<SimulationConfigForm config={sampleConfig} isActing={false} onSubmit={vi.fn()} />, {
      wrapper,
    });
    expect(screen.getByTestId('save-config-button')).toBeInTheDocument();
  });

  it('calls onSubmit with current values on valid submit', async () => {
    const onSubmit = vi.fn().mockResolvedValue(undefined);
    render(<SimulationConfigForm config={sampleConfig} isActing={false} onSubmit={onSubmit} />, {
      wrapper,
    });
    fireEvent.click(screen.getByTestId('save-config-button'));
    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        tick_interval_seconds: 60,
        progress_min: 0.01,
        progress_max: 0.1,
        mode: 'campaign',
      });
    });
  });

  it('does not call onSubmit when form is invalid', async () => {
    // Override progress_min to 0.9 (> progress_max 0.1) to force validation error
    const onSubmit = vi.fn().mockResolvedValue(undefined);
    const invalidConfig = { ...sampleConfig, progress_min: 0.9, progress_max: 0.1 };
    render(<SimulationConfigForm config={invalidConfig} isActing={false} onSubmit={onSubmit} />, {
      wrapper,
    });
    fireEvent.click(screen.getByTestId('save-config-button'));
    await waitFor(() => {
      expect(onSubmit).not.toHaveBeenCalled();
    });
  });

  it('disables save button while isActing', () => {
    render(<SimulationConfigForm config={sampleConfig} isActing={true} onSubmit={vi.fn()} />, {
      wrapper,
    });
    expect(screen.getByTestId('save-config-button')).toBeDisabled();
  });
});

// ---------------------------------------------------------------------------
// SimulationPage integration
// ---------------------------------------------------------------------------

describe('SimulationPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('shows skeleton while loading', () => {
    mockUseSimulation.mockReturnValue({
      config: null,
      isLoading: true,
      error: null,
      isActing: false,
      start: vi.fn(),
      stop: vi.fn(),
      updateConfig: vi.fn(),
      refetch: vi.fn(),
    });

    render(<SimulationPage />, { wrapper });
    // Skeletons are rendered; no status panel
    expect(screen.queryByTestId('status-panel')).not.toBeInTheDocument();
  });

  it('shows status panel and config form when loaded', () => {
    mockUseSimulation.mockReturnValue({
      config: sampleConfig,
      isLoading: false,
      error: null,
      isActing: false,
      start: vi.fn(),
      stop: vi.fn(),
      updateConfig: vi.fn(),
      refetch: vi.fn(),
    });

    render(<SimulationPage />, { wrapper });
    expect(screen.getByTestId('status-panel')).toBeInTheDocument();
    expect(screen.getByTestId('config-form')).toBeInTheDocument();
  });

  it('shows error alert on error', () => {
    mockUseSimulation.mockReturnValue({
      config: null,
      isLoading: false,
      error: 'Network error',
      isActing: false,
      start: vi.fn(),
      stop: vi.fn(),
      updateConfig: vi.fn(),
      refetch: vi.fn(),
    });

    render(<SimulationPage />, { wrapper });
    expect(screen.getByTestId('error-alert')).toBeInTheDocument();
    expect(screen.getByText('Network error')).toBeInTheDocument();
  });

  it('renders page title', () => {
    mockUseSimulation.mockReturnValue({
      config: sampleConfig,
      isLoading: false,
      error: null,
      isActing: false,
      start: vi.fn(),
      stop: vi.fn(),
      updateConfig: vi.fn(),
      refetch: vi.fn(),
    });

    render(<SimulationPage />, { wrapper });
    expect(screen.getByText('SIMULATION CONTROL')).toBeInTheDocument();
  });
});
