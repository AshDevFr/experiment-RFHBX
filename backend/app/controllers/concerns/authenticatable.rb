# frozen_string_literal: true

# JWT authentication concern for API controllers.
#
# Include in any controller that needs OIDC JWT validation.
# Provides `current_principal` with the authenticated user's claims.
#
# Usage:
#   class ApplicationController < ActionController::API
#     include Authenticatable
#   end
#
# Skip authentication for specific actions:
#   skip_before_action :authenticate_request!, only: [:health]
#
# Dev bypass:
#   Set DEV_AUTH_BYPASS=true (development only) to accept tokens issued by
#   DevAuthToken in place of real OIDC JWTs. The bypass is never active in
#   production or test; a misconfiguration is logged and silently ignored.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
    attr_reader :current_principal
  end

  private

  def authenticate_request!
    # Safety guard: if someone accidentally sets DEV_AUTH_BYPASS=true in a
    # non-development environment, log the misconfiguration and fall through
    # to normal JWT validation (which will reject the bypass token).
    if ENV["DEV_AUTH_BYPASS"] == "true" && !Rails.env.development?
      Rails.logger.error(
        "[DevAuth] DEV_AUTH_BYPASS=true is set but RAILS_ENV=#{Rails.env}. " \
        "Bypass is only permitted in development — ignoring."
      )
    end

    # Dev bypass path (development + flag only).
    if dev_bypass_active?
      token = extract_bearer_token
      if token.present?
        claims = DevAuthToken.verify(token)
        if claims
          @current_principal = Principal.new(claims)
          return
        end
      end
      # Token absent or failed dev-bypass verification — fall through to JWT.
    end

    # Normal OIDC JWT path.
    token = extract_bearer_token
    if token.nil?
      render json: { error: "unauthorized" }, status: :unauthorized
      return
    end

    claims = decode_token(token)
    @current_principal = Principal.new(claims)
  rescue JwtDecoder::DecodeError
    render json: { error: "unauthorized" }, status: :unauthorized
  end

  def dev_bypass_active?
    Rails.env.development? && ENV["DEV_AUTH_BYPASS"] == "true"
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")

    token = header.split(" ", 2).last
    token.present? ? token : nil
  end

  def decode_token(token)
    jwt_decoder.call(token)
  end

  def jwt_decoder
    @jwt_decoder ||= begin
      oidc = Rails.application.config.oidc
      fetcher = jwks_fetcher
      JwtDecoder.new(
        jwks_fetcher: fetcher,
        issuer: oidc.issuer_url,
        audience: oidc.audience
      )
    end
  end

  def jwks_fetcher
    # Use a singleton fetcher to share the JWKS cache across requests
    # within the same process.
    oidc = Rails.application.config.oidc
    JwksFetcher.instance(
      issuer_url: oidc.issuer_url,
      cache_ttl: oidc.jwks_cache_ttl
    )
  end
end
