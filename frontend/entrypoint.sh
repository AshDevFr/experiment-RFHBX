#!/bin/bash
set -e

# Write Docker-injected VITE_* env vars to .env.local so Vite can expose
# them to the browser bundle natively via import.meta.env.  Vite only reads
# .env files — it does NOT read process.env for client-side injection — so
# this is the reliable way to forward compose environment variables such as
# VITE_API_BASE_URL and VITE_DEV_AUTH_BYPASS into the browser bundle.
# The file is overwritten on every container start so stale values never
# accumulate.  An empty .env.local (when no VITE_* vars are set) is fine.
printenv | grep -E '^VITE_' > .env.local || true

# Install any packages added to package.json since the Docker image (or
# the persisted frontend_node_modules volume) was last built.
npm install

exec "$@"
