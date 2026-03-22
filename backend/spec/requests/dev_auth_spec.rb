# frozen_string_literal: true

require "rails_helper"

# NOTE: These specs stub Rails.env because we need to simulate development mode
# even when tests run in the test environment.
RSpec.describe "Dev Auth Bypass", type: :request do
  let(:protected_path) { "/api/v1/characters" }

  describe "POST /api/dev/auth" do
    context "when DEV_AUTH_BYPASS is enabled in development" do
      before do
        allow(Rails).to receive(:env).and_return(
          ActiveSupport::StringInquirer.new("development")
        )
        stub_const("ENV", ENV.to_hash.merge("DEV_AUTH_BYPASS" => "true"))
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

      it "issues a token that grants access to protected endpoints", :skip_auth do
        post "/api/dev/auth"
        token = JSON.parse(response.body)["token"]

        get protected_path, headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when DEV_AUTH_BYPASS is not set" do
      before do
        allow(Rails).to receive(:env).and_return(
          ActiveSupport::StringInquirer.new("development")
        )
        stub_const("ENV", ENV.to_hash.merge("DEV_AUTH_BYPASS" => "false"))
      end

      it "returns 404", :skip_auth do
        post "/api/dev/auth"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not in development (production guard)" do
      before do
        allow(Rails).to receive(:env).and_return(
          ActiveSupport::StringInquirer.new("production")
        )
        stub_const("ENV", ENV.to_hash.merge("DEV_AUTH_BYPASS" => "true"))
      end

      it "returns 404 — bypass NEVER active in production", :skip_auth do
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
