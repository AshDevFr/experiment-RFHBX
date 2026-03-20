# frozen_string_literal: true

# Helpers for generating test JWTs signed with an in-process RSA key.
# This avoids needing a live OIDC provider in tests.
module JwtTestHelper
  ISSUER   = "https://test-oidc.example.com"
  AUDIENCE = "test-client-id"
  KID      = "test-key-1"

  class << self
    def rsa_key
      @rsa_key ||= OpenSSL::PKey::RSA.generate(2048)
    end

    def jwk
      @jwk ||= JWT::JWK.new(rsa_key, kid: KID)
    end

    def jwks_hash
      { keys: [jwk.export] }
    end

    # Generate a valid signed JWT with the given claims.
    def generate_token(claims = {})
      payload = default_claims.merge(claims)
      headers = { kid: KID }
      JWT.encode(payload, jwk.signing_key, "RS256", headers)
    end

    # Generate a JWT signed with a different (unknown) key.
    def generate_tampered_token(claims = {})
      other_key = JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: "unknown-key")
      payload = default_claims.merge(claims)
      headers = { kid: "unknown-key" }
      JWT.encode(payload, other_key.signing_key, "RS256", headers)
    end

    # Generate an expired JWT.
    def generate_expired_token(claims = {})
      payload = default_claims.merge(claims).merge(
        exp: 1.hour.ago.to_i,
        iat: 2.hours.ago.to_i
      )
      headers = { kid: KID }
      JWT.encode(payload, jwk.signing_key, "RS256", headers)
    end

    private

    def default_claims
      {
        "sub" => "user-123",
        "email" => "frodo@shire.example.com",
        "iss" => ISSUER,
        "aud" => AUDIENCE,
        "iat" => Time.current.to_i,
        "exp" => 1.hour.from_now.to_i,
        "roles" => %w[fellowship ring-bearer]
      }
    end
  end
end
