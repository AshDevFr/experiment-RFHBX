import { ActionIcon, AppShell, Group, Text } from '@mantine/core';
import { createRootRoute, Outlet } from '@tanstack/react-router';
import { useState } from 'react';
import { CableStatus } from '../components/CableStatus';
import { useActionCable } from '../hooks/useActionCable';
import type { ConnectionStatus } from '../hooks/useQuestEventsChannel';
import { useThemeStore } from '../store/themeStore';

function CableStatusWidget() {
  const consumer = useActionCable();
  const [status, setStatus] = useState<ConnectionStatus>('connecting');

  // Monitor the consumer's connection state via a dummy subscription.
  // This lets us display a global status indicator without subscribing to
  // a specific channel here.
  const connectionMonitor = consumer.connection;
  // Action Cable exposes isOpen() / isActive() on the connection object.
  // We poll the status on each render; for a production app this could
  // be driven by a subscription's connected/disconnected callbacks instead.
  const isOpen = connectionMonitor && typeof (connectionMonitor as { isOpen?: () => boolean }).isOpen === 'function'
    ? (connectionMonitor as { isOpen: () => boolean }).isOpen()
    : false;

  // Only update if there's a meaningful difference; avoid an infinite loop by
  // not calling setState unconditionally during render.
  const derivedStatus: ConnectionStatus = isOpen ? 'connected' : 'disconnected';
  if (derivedStatus !== status) {
    setStatus(derivedStatus);
  }

  return <CableStatus status={status} />;
}

function RootLayout() {
  const colorScheme = useThemeStore((s) => s.colorScheme);
  const toggle = useThemeStore((s) => s.toggle);

  return (
    <AppShell header={{ height: 60 }} padding="md">
      <AppShell.Header>
        <Group justify="space-between" h="100%" px="md">
          <Text fw={700} style={{ letterSpacing: '0.1em' }}>
            MORDOR'S EDGE
          </Text>
          <Group>
            <CableStatusWidget />
            <ActionIcon
              variant="outline"
              size="lg"
              onClick={toggle}
              aria-label={`Switch to ${colorScheme === 'dark' ? 'light' : 'dark'} mode`}
              title={`Switch to ${colorScheme === 'dark' ? 'light' : 'dark'} mode`}
            >
              {colorScheme === 'dark' ? '\u2600' : '\u263E'}
            </ActionIcon>
          </Group>
        </Group>
      </AppShell.Header>
      <AppShell.Main>
        <Outlet />
      </AppShell.Main>
    </AppShell>
  );
}

export const Route = createRootRoute({
  component: RootLayout,
});
