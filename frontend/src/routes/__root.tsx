import { ActionIcon, AppShell, Burger, Group, NavLink, Stack, Text } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { createRootRouteWithContext, Link, Outlet, useRouterState } from '@tanstack/react-router';
import type { AuthContextValue } from '../auth/AuthContext';
import { useAuth } from '../auth/AuthProvider';
import { UserInfo } from '../components/UserInfo';
import { useThemeStore } from '../store/themeStore';

// ---------------------------------------------------------------------------
// Router context — exposed to all route `beforeLoad` / `loader` hooks.
// ---------------------------------------------------------------------------
export interface RouterContext {
  /** The current auth state. May be undefined on first render before context is wired. */
  auth: AuthContextValue | undefined;
}

// ---------------------------------------------------------------------------
// Nav links definition — single source of truth for all Phase 7 pages.
// ---------------------------------------------------------------------------
const NAV_LINKS = [
  { to: '/quests' as const, label: 'QUESTS' },
  { to: '/fellowship' as const, label: 'FELLOWSHIP' },
  { to: '/sauron' as const, label: 'SAURON' },
  { to: '/history' as const, label: 'HISTORY' },
  { to: '/simulation' as const, label: 'SIMULATION' },
  { to: '/chaos' as const, label: 'CHAOS' },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function AppNavLink({ to, label }: { to: string; label: string }) {
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const isActive = pathname === to || pathname.startsWith(`${to}/`);
  return (
    <NavLink
      component={Link}
      to={to}
      label={label}
      active={isActive}
      styles={{
        root: { textTransform: 'uppercase', letterSpacing: '0.1em', fontSize: '0.65rem' },
      }}
    />
  );
}

// ---------------------------------------------------------------------------
// Root layout
// ---------------------------------------------------------------------------

function RootLayout() {
  const colorScheme = useThemeStore((s) => s.colorScheme);
  const toggle = useThemeStore((s) => s.toggle);
  const { isAuthenticated } = useAuth();
  const [mobileNavOpen, { toggle: toggleMobileNav, close: closeMobileNav }] = useDisclosure(false);

  const hasNav = isAuthenticated;

  return (
    <AppShell
      header={{ height: 60 }}
      navbar={
        hasNav ? { width: 220, breakpoint: 'sm', collapsed: { mobile: !mobileNavOpen } } : undefined
      }
      padding="md"
    >
      {/* ---- Header ---- */}
      <AppShell.Header>
        <Group justify="space-between" h="100%" px="md">
          <Group>
            {hasNav && (
              <Burger
                opened={mobileNavOpen}
                onClick={toggleMobileNav}
                hiddenFrom="sm"
                size="sm"
                aria-label="Toggle navigation"
              />
            )}
            <Text fw={700} style={{ letterSpacing: '0.1em' }}>
              MORDOR'S EDGE
            </Text>
          </Group>
          <Group>
            <UserInfo />
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

      {/* ---- Sidebar (authenticated only) ---- */}
      {hasNav && (
        <AppShell.Navbar p="xs">
          <Stack gap={4} onClick={closeMobileNav}>
            {NAV_LINKS.map((link) => (
              <AppNavLink key={link.to} to={link.to} label={link.label} />
            ))}
          </Stack>
        </AppShell.Navbar>
      )}

      {/* ---- Main content ---- */}
      <AppShell.Main>
        <Outlet />
      </AppShell.Main>
    </AppShell>
  );
}

export const Route = createRootRouteWithContext<RouterContext>()({
  component: RootLayout,
});
