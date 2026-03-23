# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_principal

    def connect
      self.current_principal = authenticate_token!
    end

    private

    def authenticate_token!
      token = extract_token
      reject_unauthorized_connection if token.nil?

      # Dev bypass path: accept DevAuthToken-signed tokens in development.
      if dev_bypass_active?
        claims = DevAuthToken.verify(token)
        return Principal.new(claims) if claims
      end

      claims = jwt_decoder.call(token)
      Principal.new(claims)
    rescue JwtDecoder::DecodeError
      reject_unauthorized_connection
    end

    def dev_bypass_active?
      Rails.env.development? && ENV["DEV_AUTH_BYPASS"] == "true"
    end

    def extract_token
      # Prefer query param (most browser WebSocket clients cannot set headers).
      token = request.params[:token]
      return token if token.present?

      # Fall back to Authorization header for non-browser clients.
      header = request.headers["Authorization"]
      return nil unless header&.start_with?("Bearer ")

      bearer = header.split(" ", 2).last
      bearer.present? ? bearer : nil
    end

    def jwt_decoder
      oidc = Rails.application.config.oidc
      fetcher = JwksFetcher.instance(
        issuer_url: oidc.issuer_url,
        cache_ttl: oidc.jwks_cache_ttl
      )
      JwtDecoder.new(
        jwks_fetcher: fetcher,
        issuer: oidc.issuer_url,
        audience: oidc.audience
      )
    end
  end
end
