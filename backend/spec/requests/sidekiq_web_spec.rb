# frozen_string_literal: true

require "rails_helper"

# Specs for the Sidekiq Web UI route and SidekiqAuthConstraint.
#
# The route is mounted only in development (`if Rails.env.development?`).
# Specs run in the test environment, so the route is absent here — mirroring
# production behaviour.
#
# NOTE: Rails.env cannot be stubbed globally in request specs — doing so causes
# Rails 8.1's CheckPending middleware to look for the wrong database. See
# dev_auth_spec.rb for the full explanation. We therefore test the constraint
# class directly for the dev-bypass path.
RSpec.describe "Sidekiq Web UI", type: :request do
  describe "GET /admin/sidekiq" do
    it "returns 404 in test/production environments — route not mounted", :skip_auth do
      get "/admin/sidekiq"
      expect(response).to have_http_status(:not_found)
    end
  end
end

RSpec.describe SidekiqAuthConstraint do
  subject(:constraint) { described_class.new }

  let(:request) { instance_double(ActionDispatch::Request) }

  describe "#matches?" do
    context "when DEV_AUTH_BYPASS is active in development" do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
        stub_const("ENV", ENV.to_hash.merge("DEV_AUTH_BYPASS" => "true"))
      end

      it "allows access without inspecting the Authorization header" do
        # request double receives no header calls — short-circuit fires first
        expect(constraint.matches?(request)).to be true
      end
    end

    context "when no Authorization header is present" do
      before do
        allow(request).to receive(:get_header).with("HTTP_AUTHORIZATION").and_return(nil)
        allow(request).to receive(:get_header).with("AUTHORIZATION").and_return(nil)
      end

      it "returns false" do
        expect(constraint.matches?(request)).to be false
      end
    end

    context "when Authorization header is not a Bearer token" do
      before do
        allow(request).to receive(:get_header).with("HTTP_AUTHORIZATION").and_return("Basic dXNlcjpwYXNz")
        allow(request).to receive(:get_header).with("AUTHORIZATION").and_return(nil)
      end

      it "returns false" do
        expect(constraint.matches?(request)).to be false
      end
    end

    context "when OIDC issuer URL is blank (unconfigured dev environment)" do
      before do
        allow(request).to receive(:get_header).with("HTTP_AUTHORIZATION").and_return("Bearer sometoken")
        allow(request).to receive(:get_header).with("AUTHORIZATION").and_return(nil)
        oidc_config = double(
          issuer_url: "",
          jwks_cache_ttl: 300,
          audience: "test-client"
        )
        allow(Rails.application.config).to receive(:oidc).and_return(oidc_config)
      end

      it "passes through without OIDC validation" do
        expect(constraint.matches?(request)).to be true
      end
    end
  end
end
