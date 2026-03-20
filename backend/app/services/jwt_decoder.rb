# frozen_string_literal: true

# Decodes and validates a JWT using JWKS keys from the OIDC provider.
#
# Validates: signature (RS256), expiration, issuer, and audience claims.
# Returns decoded claims hash on success; raises on any failure.
class JwtDecoder
  class DecodeError < StandardError; end

  def initialize(jwks_fetcher:, issuer:, audience:)
    @jwks_fetcher = jwks_fetcher
    @issuer       = issuer
    @audience     = audience
  end

  # Decodes the given token string and returns the claims hash.
  # Raises DecodeError for any validation failure.
  def call(token)
    decoded = JWT.decode(
      token,
      nil,  # key is resolved via jwks
      true, # verify signature
      algorithms: ["RS256"],
      iss: @issuer,
      verify_iss: @issuer.present?,
      aud: @audience,
      verify_aud: @audience.present?,
      jwks: method(:jwks_loader)
    )

    decoded.first # [payload, header] — return payload only
  rescue JWT::ExpiredSignature
    raise DecodeError, "Token has expired"
  rescue JWT::InvalidIssuerError
    raise DecodeError, "Invalid token issuer"
  rescue JWT::InvalidAudError
    raise DecodeError, "Invalid token audience"
  rescue JWT::DecodeError => e
    raise DecodeError, "Token validation failed: #{e.message}"
  end

  private

  # JWKS loader callback for the jwt gem.
  # Called with options hash; on kid_not_found, forces a cache refresh.
  def jwks_loader(options)
    kid = options[:kid_not_found] ? nil : options[:kid]
    @jwks_fetcher.call(kid: options[:kid_not_found] ? options[:kid] : nil)
  end
end
