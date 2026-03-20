# frozen_string_literal: true

# OIDC / JWT configuration
# ────────────────────────────────────────────────────────────────────
# Environment variables:
#   OIDC_ISSUER_URL    – Base URL of the OIDC provider (e.g. https://auth.example.com/realms/myapp)
#   OIDC_CLIENT_ID     – OAuth2 client ID registered with the provider
#   OIDC_CLIENT_SECRET – OAuth2 client secret (used only for confidential flows, not JWT validation)
#   OIDC_AUDIENCE      – Expected "aud" claim in JWTs (defaults to OIDC_CLIENT_ID)
#   OIDC_JWKS_CACHE_TTL – JWKS key cache TTL in seconds (default: 3600)
# ────────────────────────────────────────────────────────────────────

Rails.application.config.oidc = ActiveSupport::OrderedOptions.new.tap do |cfg|
  cfg.issuer_url    = ENV.fetch("OIDC_ISSUER_URL", nil)
  cfg.client_id     = ENV.fetch("OIDC_CLIENT_ID", nil)
  cfg.client_secret = ENV.fetch("OIDC_CLIENT_SECRET", nil)
  cfg.audience      = ENV.fetch("OIDC_AUDIENCE") { cfg.client_id }
  cfg.jwks_cache_ttl = ENV.fetch("OIDC_JWKS_CACHE_TTL", 3600).to_i
end
