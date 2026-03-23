# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Allow the Docker Compose service name so that requests originating from
  # the frontend container (which hits http://backend:3000) are not blocked
  # by ActionDispatch::HostAuthorization.
  config.hosts << "backend"

  config.active_job.queue_adapter = :sidekiq

  # Allow WebSocket upgrades from Vite dev server (covers both Docker and native dev topologies).
  # http://0.0.0.0:5173 — origin sent when Vite binds to 0.0.0.0 inside Docker
  # http://localhost:5173 — origin sent in native (non-Docker) dev setups
  config.action_cable.allowed_request_origins = [
    "http://localhost:5173",
    "http://0.0.0.0:5173"
  ]

  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true

  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
end
