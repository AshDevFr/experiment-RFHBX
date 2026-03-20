# frozen_string_literal: true

require "rails_helper"

RSpec.describe JwksFetcher do
  include ActiveSupport::Testing::TimeHelpers

  let(:issuer_url) { JwtTestHelper::ISSUER }
  let(:fetcher) { described_class.new(issuer_url: issuer_url, cache_ttl: 60) }

  describe "#call" do
    it "fetches JWKS from the provider" do
      keys = fetcher.call

      expect(keys).to be_a(JWT::JWK::Set)
      expect(WebMock).to have_requested(:get, "#{issuer_url}/.well-known/jwks.json").once
    end

    it "caches keys across calls" do
      fetcher.call
      fetcher.call

      expect(WebMock).to have_requested(:get, "#{issuer_url}/.well-known/jwks.json").once
    end

    it "refreshes cache when TTL expires" do
      fetcher.call

      travel_to(2.minutes.from_now) do
        fetcher.call
      end

      expect(WebMock).to have_requested(:get, "#{issuer_url}/.well-known/jwks.json").twice
    end

    it "raises FetchError on HTTP failure" do
      stub_request(:get, "#{issuer_url}/.well-known/jwks.json")
        .to_return(status: 500, body: "Internal Server Error")

      new_fetcher = described_class.new(issuer_url: issuer_url, cache_ttl: 0)

      expect { new_fetcher.call }.to raise_error(JwksFetcher::FetchError, /HTTP 500/)
    end

    it "raises FetchError on invalid JSON" do
      stub_request(:get, "#{issuer_url}/.well-known/jwks.json")
        .to_return(status: 200, body: "not json")

      new_fetcher = described_class.new(issuer_url: issuer_url, cache_ttl: 0)

      expect { new_fetcher.call }.to raise_error(JwksFetcher::FetchError, /Invalid JWKS JSON/)
    end
  end

  describe ".instance" do
    it "returns the same instance for the same issuer URL" do
      described_class.reset!
      a = described_class.instance(issuer_url: "https://a.example.com")
      b = described_class.instance(issuer_url: "https://a.example.com")

      expect(a).to be(b)
    end

    it "returns different instances for different issuer URLs" do
      described_class.reset!
      a = described_class.instance(issuer_url: "https://a.example.com")
      b = described_class.instance(issuer_url: "https://b.example.com")

      expect(a).not_to be(b)
    end
  end

  describe ".reset!" do
    it "clears cached instances" do
      described_class.reset!
      a = described_class.instance(issuer_url: "https://reset-test.example.com")
      described_class.reset!
      b = described_class.instance(issuer_url: "https://reset-test.example.com")

      expect(a).not_to be(b)
    end
  end
end
