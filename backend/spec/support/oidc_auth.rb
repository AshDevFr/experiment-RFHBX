# frozen_string_literal: true

# Configure OIDC settings for test environment and stub the JWKS fetcher
# so tests never hit a real OIDC provider.
RSpec.configure do |config|
  config.before(:suite) do
    Rails.application.config.oidc.issuer_url = JwtTestHelper::ISSUER
    Rails.application.config.oidc.client_id  = JwtTestHelper::AUDIENCE
    Rails.application.config.oidc.audience   = JwtTestHelper::AUDIENCE
    Rails.application.config.oidc.jwks_cache_ttl = 3600
  end

  config.before do
    JwksFetcher.reset!

    # Stub the JWKS HTTP fetch to return our test keyset
    jwks_json = JwtTestHelper.jwks_hash.to_json
    stub_request(:get, "#{JwtTestHelper::ISSUER}/.well-known/jwks.json")
      .to_return(status: 200, body: jwks_json, headers: { "Content-Type" => "application/json" })
  end
end
