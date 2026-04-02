#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# wait-for-services.sh
#
# Belt-and-suspenders health gate that runs inside the Playwright container.
# Docker Compose healthchecks (service_healthy) should have already gated
# container startup, but CI runners can be flaky so we double-check here.
#
# Key design decisions:
#   - Uses `node` (guaranteed in the Playwright image) instead of curl for
#     HTTP checks — more portable and avoids curl flag inconsistencies.
#   - Environment variables are resolved in the OUTER shell, not inside
#     a bash -c '' subshell, to avoid single-quote variable expansion issues.
#   - Errors are printed, not suppressed, so CI logs show the real failure.
# ---------------------------------------------------------------------------

BACKEND_TIMEOUT=${BACKEND_TIMEOUT:-180}
FRONTEND_TIMEOUT=${FRONTEND_TIMEOUT:-180}

BACKEND_URL="${API_BASE_URL:-http://backend:3000}"
FRONTEND_URL="${BASE_URL:-http://frontend:5173}"

# ---------------------------------------------------------------------------
# check_http URL
#   Returns 0 if the URL responds with status < 500, 1 otherwise.
#   Prints the failure reason on error (not suppressed).
# ---------------------------------------------------------------------------
check_http() {
  node -e "
    const http = require('http');
    const url = new URL('$1');
    const req = http.get({ hostname: url.hostname, port: url.port, path: url.pathname, timeout: 5000 }, (res) => {
      process.exit(res.statusCode < 500 ? 0 : 1);
    });
    req.on('error', (e) => { console.error('  check_http error: ' + e.message); process.exit(1); });
    req.on('timeout', () => { console.error('  check_http timeout'); req.destroy(); process.exit(1); });
  " 2>&1
  return $?
}

# ---------------------------------------------------------------------------
# wait_for NAME URL TIMEOUT
# ---------------------------------------------------------------------------
wait_for() {
  local name="$1" url="$2" timeout_secs="$3"
  local deadline=$((SECONDS + timeout_secs))

  echo "Waiting for ${name} at ${url} (timeout: ${timeout_secs}s)..."

  # Quick DNS check — helps diagnose Docker networking issues.
  local host
  host=$(node -e "console.log(new URL('${url}').hostname)")
  echo "  resolving ${host}..."
  if getent hosts "$host" >/dev/null 2>&1; then
    echo "  ${host} -> $(getent hosts "$host" | awk '{print $1}')"
  else
    echo "  WARNING: DNS lookup for ${host} failed — Docker network may not be ready yet"
  fi

  while [ $SECONDS -lt $deadline ]; do
    if check_http "$url"; then
      echo "  ${name}: ready"
      return 0
    fi
    local remaining=$((deadline - SECONDS))
    echo "  ${name}: not ready — retrying in 3s... (${remaining}s remaining)"
    sleep 3
  done

  echo "ERROR: ${name} did not become ready within ${timeout_secs}s"
  echo "  Last DNS lookup for ${host}:"
  getent hosts "$host" 2>&1 || echo "  (DNS resolution failed)"
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
wait_for "backend" "${BACKEND_URL}/api/health" "$BACKEND_TIMEOUT"
wait_for "frontend" "$FRONTEND_URL" "$FRONTEND_TIMEOUT"

echo "All services are up — running Playwright tests."
exec "$@"
