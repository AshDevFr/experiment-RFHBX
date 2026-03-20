# frozen_string_literal: true

require "net/http"
require "json"

# Fetches and caches JWKS keys from an OIDC provider's well-known endpoint.
#
# Keys are cached in-memory with a configurable TTL to avoid hitting
# the provider on every request. The cache is invalidated when:
#   1. The TTL expires, OR
#   2. A JWT references a kid not found in the current keyset (key rotation)
class JwksFetcher
  class FetchError < StandardError; end

  # Returns a shared instance per issuer URL, so the JWKS cache is reused
  # across requests within the same process.
  def self.instance(issuer_url:, cache_ttl: 3600)
    @instances ||= {}
    key = issuer_url.to_s
    @instances[key] ||= new(issuer_url: issuer_url, cache_ttl: cache_ttl)
  end

  # Reset all cached instances (useful in tests)
  def self.reset!
    @instances = {}
  end

  def initialize(issuer_url:, cache_ttl: 3600)
    @issuer_url = issuer_url
    @cache_ttl  = cache_ttl
    @mutex      = Mutex.new
    @cached_keys = nil
    @cached_at   = nil
  end

  # Returns an array of JWT::JWK keys. If +kid+ is provided and not found
  # in the current cache, forces a refresh (handles key rotation).
  def call(kid: nil)
    keys = cached_keys

    if kid && !keys.find { |k| k[:kid] == kid }
      keys = fetch_and_cache!
    end

    keys
  end

  private

  def cached_keys
    @mutex.synchronize do
      if cache_expired?
        fetch_and_cache_locked!
      else
        @cached_keys
      end
    end
  end

  def fetch_and_cache!
    @mutex.synchronize { fetch_and_cache_locked! }
  end

  def fetch_and_cache_locked!
    jwks_uri = "#{@issuer_url.chomp('/')}/.well-known/jwks.json"
    uri = URI(jwks_uri)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                               open_timeout: 5, read_timeout: 5) do |http|
      http.get(uri.request_uri)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise FetchError, "JWKS fetch failed: HTTP #{response.code} from #{jwks_uri}"
    end

    jwks_hash = JSON.parse(response.body)
    @cached_keys = JWT::JWK::Set.new(jwks_hash)
    @cached_at   = Time.current
    @cached_keys
  rescue JSON::ParserError => e
    raise FetchError, "Invalid JWKS JSON: #{e.message}"
  end

  def cache_expired?
    @cached_keys.nil? || @cached_at.nil? || (Time.current - @cached_at) > @cache_ttl
  end
end
