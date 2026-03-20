# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_cable/engine"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module MordorsEdge
  class Application < Rails::Application
    config.load_defaults 8.1

    # API-only mode — no views, cookies, or sessions
    config.api_only = true

    # Application version (referenced by the health endpoint)
    config.version = "0.1.0"

    # Action Cable allowed origins — reads from CABLE_ALLOWED_ORIGINS env var
    # (comma-separated). Defaults to the Vite frontend dev server.
    config.action_cable.allowed_request_origins = ENV
      .fetch("CABLE_ALLOWED_ORIGINS", "http://localhost:5173")
      .split(",")
      .map(&:strip)

    # Generator defaults: use RSpec, not MiniTest
    config.generators do |g|
      g.test_framework :rspec
      g.helper false
      g.assets false
      g.view_specs false
      g.helper_specs false
    end
  end
end
