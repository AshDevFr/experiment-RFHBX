# frozen_string_literal: true

require "rails_helper"

RSpec.describe "JWT Authentication", :skip_auth, type: :request do
  let(:valid_token) { JwtTestHelper.generate_token }
  let(:expired_token) { JwtTestHelper.generate_expired_token }
  let(:tampered_token) { JwtTestHelper.generate_tampered_token }

  # Use a protected endpoint (characters index) for auth testing
  let(:protected_path) { "/api/v1/characters" }

  describe "valid token" do
    it "returns 200 and allows access" do
      get protected_path, headers: { "Authorization" => "Bearer #{valid_token}" }

      expect(response).to have_http_status(:ok)
    end

    it "extracts principal claims from the token" do
      get protected_path, headers: { "Authorization" => "Bearer #{valid_token}" }

      expect(response).to have_http_status(:ok)
    end

    it "accepts tokens with custom claims" do
      token = JwtTestHelper.generate_token(
        "sub" => "aragorn-42",
        "email" => "aragorn@gondor.example.com",
        "roles" => %w[king ranger]
      )

      get protected_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "expired token" do
    it "returns 401 with error message" do
      get protected_path, headers: { "Authorization" => "Bearer #{expired_token}" }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("expired")
    end
  end

  describe "tampered token" do
    it "returns 401 with error message" do
      get protected_path, headers: { "Authorization" => "Bearer #{tampered_token}" }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to be_present
    end
  end

  describe "missing token" do
    it "returns 401 when Authorization header is absent" do
      get protected_path

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Missing")
    end

    it "returns 401 when Authorization header is not Bearer" do
      get protected_path, headers: { "Authorization" => "Basic dXNlcjpwYXNz" }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Missing")
    end

    it "returns 401 when Bearer token is empty" do
      get protected_path, headers: { "Authorization" => "Bearer " }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "unprotected routes" do
    it "health check is accessible without a token" do
      get "/api/health"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("ok")
    end
  end

  describe "invalid issuer" do
    it "returns 401 when issuer does not match" do
      token = JwtTestHelper.generate_token("iss" => "https://evil.example.com")

      get protected_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to be_present
    end
  end

  describe "invalid audience" do
    it "returns 401 when audience does not match" do
      token = JwtTestHelper.generate_token("aud" => "wrong-audience")

      get protected_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to be_present
    end
  end
end
