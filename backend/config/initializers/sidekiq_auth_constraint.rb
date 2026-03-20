# frozen_string_literal: true

# Rack constraint that validates a Bearer JWT token for the Sidekiq Web UI.
#
# Used in routes.rb:
#   mount Sidekiq::Web => "/admin/sidekiq", constraints: SidekiqAuthConstraint.new
#
# Any request without a valid Bearer token is rejected with HTTP 401 before
# the Sidekiq Rack application handles it. If OIDC is not configured (e.g.
# development without a provider), the constraint passes through.
class SidekiqAuthConstraint
  def matches?(request)
    header = request.get_header("HTTP_AUTHORIZATION") || request.get_header("AUTHORIZATION")
    return false unless header&.start_with?("Bearer ")

    token = header.split(" ", 2).last
    return false if token.blank?

    oidc = Rails.application.config.oidc

    # Skip validation when OIDC is not configured (development without a provider)
    return true if oidc.issuer_url.blank?

    begin
      fetcher = JwksFetcher.instance(
        issuer_url: oidc.issuer_url,
        cache_ttl: oidc.jwks_cache_ttl
      )
      decoder = JwtDecoder.new(
        jwks_fetcher: fetcher,
        issuer: oidc.issuer_url,
        audience: oidc.audience
      )
      decoder.call(token)
      true
    rescue JwtDecoder::DecodeError, JwksFetcher::FetchError
      false
    end
  end
end
