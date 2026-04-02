import { TanStackRouterVite } from '@tanstack/router-plugin/vite';
import react from '@vitejs/plugin-react-swc';
import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
  // Load env vars from .env files (including .env.local written by
  // entrypoint.sh at container start).  Using an empty prefix reads ALL vars,
  // not just VITE_-prefixed ones, so VITE_API_BASE_URL is available here for
  // the proxy target.
  //
  // Note: VITE_* variables in .env.local are automatically exposed to the
  // browser bundle as import.meta.env.VITE_* by Vite's native env handling.
  // No manual `define` override is needed or safe — using `define` to override
  // import.meta.env.* keys conflicts with Vite 8's own env processing and
  // causes the values to be silently ignored in the browser bundle.
  const env = loadEnv(mode, process.cwd(), '');

  const apiTarget = env.VITE_API_BASE_URL || 'http://localhost:3000';

  return {
    plugins: [
      TanStackRouterVite({
        routesDirectory: './src/routes',
        generatedRouteTree: './src/routeTree.gen.ts',
      }),
      react(),
    ],
    server: {
      host: true,
      proxy: {
        '/api': {
          target: apiTarget,
          changeOrigin: true,
        },
      },
    },
  };
});
