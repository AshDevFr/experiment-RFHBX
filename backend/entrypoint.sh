#!/bin/bash
set -e

# Remove stale Puma PID file (left behind on ungraceful shutdown)
rm -f /app/tmp/pids/server.pid

# Install any gems added to the Gemfile since the Docker image (or the
# persisted backend_bundle volume) was last built.  `bundle check` exits
# 0 when everything is satisfied, so `bundle install` only runs when
# there is actually something new to fetch.
bundle check || bundle install

# Wait for PostgreSQL to be reachable before running db:prepare.
# Docker Compose depends_on with service_healthy should guarantee this,
# but DNS resolution can lag behind container readiness when containers
# are recycled (e.g., "Recreated" while postgres is still "Running"
# from a previous session on a stale network). Retrying here makes the
# entrypoint resilient to transient Docker DNS propagation delays.
MAX_RETRIES=10
RETRY_INTERVAL=2
for i in $(seq 1 $MAX_RETRIES); do
  if bundle exec rails runner "begin; ActiveRecord::Base.connection; rescue ActiveRecord::NoDatabaseError; end" 2>/dev/null; then
    break
  fi
  if [ "$i" -eq "$MAX_RETRIES" ]; then
    echo "ERROR: Could not connect to database after $MAX_RETRIES attempts" >&2
    exit 1
  fi
  echo "Waiting for database connection... (attempt $i/$MAX_RETRIES)"
  sleep $RETRY_INTERVAL
done

# Prepare database (create if needed, run migrations)
bundle exec rails db:prepare

exec "$@"
