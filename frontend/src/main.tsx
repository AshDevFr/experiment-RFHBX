import { MantineProvider } from '@mantine/core';
import { createRouter, RouterProvider } from '@tanstack/react-router';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@mantine/core/styles.css';
import { ActionCableProvider } from './hooks/useActionCable';
import { routeTree } from './routeTree.gen';
import { useThemeStore } from './store/themeStore';
import { theme } from './theme';

const router = createRouter({ routeTree });

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

function AppRoot() {
  const colorScheme = useThemeStore((s) => s.colorScheme);
  return (
    <MantineProvider theme={theme} forceColorScheme={colorScheme}>
      <ActionCableProvider>
        <RouterProvider router={router} />
      </ActionCableProvider>
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
