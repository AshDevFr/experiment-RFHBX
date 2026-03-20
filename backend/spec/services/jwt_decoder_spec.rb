# frozen_string_literal: true

require "rails_helper"

RSpec.describe JwtDecoder do
  let(:issuer) { JwtTestHelper::ISSUER }
  let(:audience) { JwtTestHelper::AUDIENCE }
  let(:fetcher) { JwksFetcher.new(issuer_url: issuer, cache_ttl: 3600) }
  let(:decoder) { described_class.new(jwks_fetcher: fetcher, issuer: issuer, audience: audience) }

  describe "#call" do
    it "decodes a valid token and returns claims" do
      token = JwtTestHelper.generate_token
      claims = decoder.call(token)

      expect(claims["sub"]).to eq("user-123")
      expect(claims["email"]).to eq("frodo@shire.example.com")
      expect(claims["roles"]).to eq(%w[fellowship ring-bearer])
    end

    it "raises DecodeError for expired tokens" do
      token = JwtTestHelper.generate_expired_token

      expect { decoder.call(token) }.to raise_error(
        JwtDecoder::DecodeError, /expired/i
      )
    end

    it "raises DecodeError for tampered tokens" do
      token = JwtTestHelper.generate_tampered_token

      expect { decoder.call(token) }.to raise_error(JwtDecoder::DecodeError)
    end

    it "raises DecodeError for invalid issuer" do
      token = JwtTestHelper.generate_token("iss" => "https://evil.example.com")

      expect { decoder.call(token) }.to raise_error(
        JwtDecoder::DecodeError, /issuer/i
      )
    end

    it "raises DecodeError for invalid audience" do
      token = JwtTestHelper.generate_token("aud" => "wrong-client")

      expect { decoder.call(token) }.to raise_error(
        JwtDecoder::DecodeError, /audience/i
      )
    end

    it "raises DecodeError for malformed tokens" do
      expect { decoder.call("not.a.jwt") }.to raise_error(JwtDecoder::DecodeError)
    end

    it "raises DecodeError for completely invalid input" do
      expect { decoder.call("garbage") }.to raise_error(JwtDecoder::DecodeError)
    end
  end
end
