# frozen_string_literal: true

require "sidekiq/web"
require "rack/session/cookie"

# ── Sidekiq::Web middleware ────────────────────────────────────────────────────
# Rails is in API-only mode, so the standard session and cookie middleware are
# not loaded. We add Rack::Session::Cookie directly to Sidekiq::Web's Rack app.
Sidekiq::Web.use Rack::Session::Cookie,
                 key: "_sidekiq_session",
                 same_site: true,
                 secret: Rails.application.secret_key_base

# HTTP Basic Auth protects the Web UI in all environments.
# Full auth integration (e.g. Devise/JWT) is planned for Phase 6.
sidekiq_web_user     = ENV.fetch("SIDEKIQ_WEB_USER", "admin")
sidekiq_web_password = ENV.fetch("SIDEKIQ_WEB_PASSWORD", "sidekiq_password")

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  ActiveSupport::SecurityUtils.secure_compare(
    ::Digest::SHA256.hexdigest(user),
    ::Digest::SHA256.hexdigest(sidekiq_web_user)
  ) &
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(password),
      ::Digest::SHA256.hexdigest(sidekiq_web_password)
    )
end

# ── Sidekiq server / client configuration ─────────────────────────────────────
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Load sidekiq-cron schedule from config file (if present).
  # ERB is evaluated first so cron expressions can reference ENV vars.
  cron_schedule_file = Rails.root.join("config/sidekiq_cron.yml")
  if File.exist?(cron_schedule_file)
    rendered = ERB.new(File.read(cron_schedule_file)).result
    Sidekiq::Cron::Job.load_from_hash(YAML.safe_load(rendered) || {})
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
