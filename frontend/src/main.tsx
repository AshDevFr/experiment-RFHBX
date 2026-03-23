import { MantineProvider } from '@mantine/core';
import { Notifications } from '@mantine/notifications';
import { createRouter, RouterProvider } from '@tanstack/react-router';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@mantine/core/styles.css';
import '@mantine/notifications/styles.css';
import type { AuthContextValue } from './auth/AuthContext';
import { AuthProvider, useAuth } from './auth/AuthProvider';
import { ActionCableProvider } from './hooks/useActionCable';
import { routeTree } from './routeTree.gen';
import { useThemeStore } from './store/themeStore';
import { theme } from './theme';

const router = createRouter({
  routeTree,
  context: {
    // auth is populated at render time by RouterWithAuth below.
    auth: undefined as AuthContextValue | undefined,
  },
});

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

/**
 * Renders the RouterProvider with the current auth context injected.
 * Must be rendered inside <AuthProvider> so useAuth() is available.
 */
function RouterWithAuth() {
  const auth = useAuth();
  return <RouterProvider router={router} context={{ auth }} />;
}

function AppRoot() {
  const colorScheme = useThemeStore((s) => s.colorScheme);
  return (
    <MantineProvider theme={theme} forceColorScheme={colorScheme}>
      <Notifications />
      <AuthProvider>
        <ActionCableProvider>
          <RouterWithAuth />
        </ActionCableProvider>
      </AuthProvider>
    </MantineProvider>
  );
}

const rootEl = document.getElementById('root');
if (!rootEl) throw new Error('Root element #root not found in document');

createRoot(rootEl).render(
  <StrictMode>
    <AppRoot />
  </StrictMode>,
);
