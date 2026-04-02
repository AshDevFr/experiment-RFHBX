#!/bin/bash
set -e

# Configurable timeouts (seconds). Since Docker Compose healthchecks already
# gate service startup, these are a belt-and-suspenders safeguard inside the
# Playwright container.  Defaults are generous to absorb slow CI runners.
BACKEND_TIMEOUT=${BACKEND_TIMEOUT:-120}
FRONTEND_TIMEOUT=${FRONTEND_TIMEOUT:-120}

# ---------------------------------------------------------------------------
# Wait for backend
# ---------------------------------------------------------------------------
echo "Waiting for backend at ${API_BASE_URL:-http://backend:3000} (timeout: ${BACKEND_TIMEOUT}s)..."
timeout "$BACKEND_TIMEOUT" bash -c '
  until curl -sf "${API_BASE_URL:-http://backend:3000}/api/health" > /dev/null 2>&1; do
    echo "  backend: not ready — retrying in 3s..."
    sleep 3
  done
'
echo "  backend: ready"

# ---------------------------------------------------------------------------
# Wait for frontend
# ---------------------------------------------------------------------------
echo "Waiting for frontend at ${BASE_URL:-http://frontend:5173} (timeout: ${FRONTEND_TIMEOUT}s)..."
timeout "$FRONTEND_TIMEOUT" bash -c '
  until curl -sf "${BASE_URL:-http://frontend:5173}" > /dev/null 2>&1; do
    echo "  frontend: not ready — retrying in 3s..."
    sleep 3
  done
'
echo "  frontend: ready"

echo "All services are up — running Playwright tests."
exec "$@"
