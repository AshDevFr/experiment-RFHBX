# frozen_string_literal: true

# Generates and verifies signed dev-bypass tokens using Rails' MessageVerifier.
#
# These tokens are ONLY valid when:
#   - Rails.env.development? is true
#   - DEV_AUTH_BYPASS=true env var is set
#
# They are signed with secret_key_base so they cannot be forged, but they
# intentionally bypass OIDC validation for local development convenience.
class DevAuthToken
  VERIFIER_PURPOSE = "dev_auth_bypass"

  DEV_CLAIMS = {
    "sub"   => "dev-user",
    "email" => "dev@mordors-edge.local",
    "name"  => "Dev User",
    "roles" => []
  }.freeze

  # Generate a signed dev bypass token containing the dev user's claims.
  def self.generate
    verifier.generate(DEV_CLAIMS)
  end

  # Verify a token and return its claims hash, or nil if invalid/tampered.
  def self.verify(token)
    verifier.verify(token)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
    nil
  end

  private_class_method def self.verifier
    ActiveSupport::MessageVerifier.new(
      Rails.application.secret_key_base,
      serializer: JSON,
      purpose: VERIFIER_PURPOSE
    )
  end
end
