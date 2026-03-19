#!/bin/bash
set -e

# Remove stale Puma PID file (left behind on ungraceful shutdown)
rm -f /app/tmp/pids/server.pid

# Strip Windows CRLF line endings from scripts (bind-mount may carry
# host line endings; CRLF shebangs cause "bad interpreter" errors)
if command -v sed > /dev/null 2>&1; then
  sed -i 's/\r$//' /app/bin/*
fi

# Ensure bin/ scripts are executable (bind-mount may lose execute bit)
chmod +x /app/bin/*

# Prepare database (create if needed, run migrations)
bundle exec rails db:prepare

exec "$@"
