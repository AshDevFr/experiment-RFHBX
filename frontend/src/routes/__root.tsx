import { ActionIcon, AppShell, Group, Text } from '@mantine/core';
import { createRootRoute, Outlet } from '@tanstack/react-router';
import { CableStatus } from '../components/CableStatus';
import { useQuestEventsChannel } from '../hooks/useQuestEventsChannel';
import { useThemeStore } from '../store/themeStore';

/**
 * Uses the quest events channel subscription to derive a global cable
 * connection status indicator shown in the app header.
 */
function CableStatusWidget() {
  const { connectionStatus } = useQuestEventsChannel();
  return <CableStatus status={connectionStatus} />;
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
