import { MantineProvider } from '@mantine/core';
import { cleanup, render, screen } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, describe, expect, it } from 'vitest';
import { ThreatLevelIndicator } from './ThreatLevelIndicator';

function wrapper({ children }: { children: ReactNode }) {
  return <MantineProvider>{children}</MantineProvider>;
}

describe('ThreatLevelIndicator', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders the threat level value', () => {
    render(<ThreatLevelIndicator level={7} region="Mordor" message="The Eye turns" />, { wrapper });
    expect(screen.getByTestId('threat-level-value')).toHaveTextContent('7');
  });

  it('renders the region name', () => {
    render(<ThreatLevelIndicator level={3} region="The Shire" message="A calm gaze" />, {
      wrapper,
    });
    expect(screen.getByTestId('threat-region')).toHaveTextContent('The Shire');
  });

  it('renders the message', () => {
    render(<ThreatLevelIndicator level={5} region="Rivendell" message="Shadows stir" />, {
      wrapper,
    });
    expect(screen.getByTestId('threat-message')).toHaveTextContent('Shadows stir');
  });

  it('renders the indicator container', () => {
    render(<ThreatLevelIndicator level={0} region="Rohan" message="Peace" />, { wrapper });
    expect(screen.getByTestId('threat-indicator')).toBeInTheDocument();
  });
});
