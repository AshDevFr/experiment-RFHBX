import { Outlet, createRootRoute } from '@tanstack/react-router'
import { ActionIcon, AppShell, Group, Text } from '@mantine/core'
import { useThemeStore } from '../store/themeStore'

function RootLayout() {
  const colorScheme = useThemeStore((s) => s.colorScheme)
  const toggle = useThemeStore((s) => s.toggle)

  return (
    <AppShell header={{ height: 60 }} padding="md">
      <AppShell.Header>
        <Group justify="space-between" h="100%" px="md">
          <Text fw={700} style={{ letterSpacing: '0.1em' }}>
            MORDOR'S EDGE
          </Text>
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
      </AppShell.Header>
      <AppShell.Main>
        <Outlet />
      </AppShell.Main>
    </AppShell>
  )
}

export const Route = createRootRoute({
  component: RootLayout,
})
