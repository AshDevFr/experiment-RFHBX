# frozen_string_literal: true

# Value object representing the authenticated user extracted from a JWT.
# Accessible via `current_principal` in controllers.
class Principal
  attr_reader :sub, :email, :roles, :claims

  def initialize(claims)
    @claims = claims.freeze
    @sub    = claims["sub"]
    @email  = claims["email"]
    @roles  = extract_roles(claims)
  end

  def to_h
    { sub: sub, email: email, roles: roles }
  end

  private

  def extract_roles(claims)
    # Support multiple common OIDC role claim formats:
    #   - "roles"                          (simple array)
    #   - "realm_access.roles"             (Keycloak)
    #   - "groups"                         (Dex / generic)
    roles = claims["roles"] ||
            claims.dig("realm_access", "roles") ||
            claims["groups"] ||
            []
    Array(roles)
  end
end
