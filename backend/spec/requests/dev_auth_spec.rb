# frozen_string_literal: true

require "rails_helper"

# NOTE: These specs use method-level stubs instead of stubbing Rails.env
# globally, because Rails 8.1's ActiveRecord::Migration::CheckPending
# middleware resolves the database from Rails.env at request time. Stubbing
# Rails.env to "development" causes it to look for mordors_edge_development,
# which does not exist in CI.
RSpec.describe "Dev Auth Bypass", type: :request do
  let(:protected_path) { "/api/v1/characters" }

  describe "POST /api/dev/auth" do
    context "when DEV_AUTH_BYPASS is enabled (simulated development)" do
      before do
        allow_any_instance_of(Api::Dev::AuthController)
          .to receive(:dev_auth_allowed?).and_return(true)
      end

      it "returns 200 with a token and dev user info", :skip_auth do
        post "/api/dev/auth"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["token"]).to be_present
        expect(body["user"]["email"]).to eq("dev@mordors-edge.local")
        expect(body["user"]["name"]).to eq("Dev User")
        expect(body["user"]["sub"]).to eq("dev-user")
      end

      it "issues a token that grants access to protected endpoints via dev bypass", :skip_auth do
        # Enable dev bypass on the Authenticatable concern too, so the token
        # issued by DevAuthToken is accepted on the protected endpoint.
        allow_any_instance_of(ApplicationController)
          .to receive(:dev_bypass_active?).and_return(true)

        post "/api/dev/auth"
        token = JSON.parse(response.body)["token"]

        get protected_path, headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
      end

      # Regression test for #98: requests from the frontend container arrive
      # with Host: backend:3000 (the Docker Compose service name). Without the
      # config.hosts entry in development.rb, HostAuthorization rejects with 403.
      # In test env, config.hosts is cleared so all hosts pass; this spec
      # documents the intent and guards against future host-filtering regressions.
      it "accepts requests with the Docker service hostname (Host: backend:3000)", :skip_auth do
        post "/api/dev/auth", headers: { "Host" => "backend:3000" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when DEV_AUTH_BYPASS is not set" do
      # Don't stub dev_auth_allowed? — it returns false by default in test env.
      it "returns 404", :skip_auth do
        post "/api/dev/auth"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not in development (production guard)" do
      # In test (non-development) env, the controller guard rejects with 404.
      # This verifies the defence-in-depth behaviour without needing to stub
      # Rails.env to "production" (which breaks middleware DB lookups).
      it "returns 404 — bypass NEVER active outside development", :skip_auth do
        stub_const("ENV", ENV.to_hash.merge("DEV_AUTH_BYPASS" => "true"))
        post "/api/dev/auth"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DevAuthToken" do
    it "generates and verifies a round-trip token" do
      token = DevAuthToken.generate
      claims = DevAuthToken.verify(token)
      expect(claims).to include(
        "sub"   => "dev-user",
        "email" => "dev@mordors-edge.local",
        "name"  => "Dev User"
      )
    end

    it "returns nil for a tampered token" do
      token = DevAuthToken.generate
      tampered = "#{token[0..-5]}XXXX"
      expect(DevAuthToken.verify(tampered)).to be_nil
    end

    it "returns nil for an empty string" do
      expect(DevAuthToken.verify("")).to be_nil
    end

    it "returns nil for a JWT-formatted string (wrong format)" do
      jwt_like = "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyIn0.signature"
      expect(DevAuthToken.verify(jwt_like)).to be_nil
    end
  end
end
