import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { RouterProvider, createRouter } from '@tanstack/react-router'
import { MantineProvider } from '@mantine/core'
import '@mantine/core/styles.css'
import { theme } from './theme'
import { routeTree } from './routeTree.gen'
import { useThemeStore } from './store/themeStore'

const router = createRouter({ routeTree })

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}

function AppRoot() {
  const colorScheme = useThemeStore((s) => s.colorScheme)
  return (
    <MantineProvider theme={theme} forceColorScheme={colorScheme}>
      <RouterProvider router={router} />
    </MantineProvider>
  )
}

const rootEl = document.getElementById('root')
if (!rootEl) throw new Error('Root element #root not found in document')

createRoot(rootEl).render(
  <StrictMode>
    <AppRoot />
  </StrictMode>,
)
