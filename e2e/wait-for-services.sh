#!/bin/bash
set -e

# Wait for backend API to be reachable
echo "Waiting for backend at ${API_BASE_URL:-http://backend:3000}..."
timeout 300 bash -c '
  until curl -sf "${API_BASE_URL:-http://backend:3000}/api/health" > /dev/null 2>&1; do
    sleep 3
  done
'
echo "  backend: ready"

# Wait for frontend to be reachable
echo "Waiting for frontend at ${BASE_URL:-http://frontend:5173}..."
timeout 300 bash -c '
  until curl -sf "${BASE_URL:-http://frontend:5173}" > /dev/null 2>&1; do
    sleep 3
  done
'
echo "  frontend: ready"

echo "All services are up — running Playwright tests."
exec "$@"
