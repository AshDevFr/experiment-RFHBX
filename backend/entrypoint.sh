#!/bin/bash
set -e

# Remove stale Puma PID file (left behind on ungraceful shutdown)
rm -f /app/tmp/pids/server.pid

# Prepare database (create if needed, run migrations)
bundle exec rails db:prepare

exec "$@"
