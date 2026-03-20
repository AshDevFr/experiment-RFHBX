# frozen_string_literal: true

require "rails_helper"

# Per-controller authentication guard specs (Issue #51 — Phase 6.2).
#
# Each controller context verifies:
#   1. Authenticated request (valid JWT) receives the expected success response.
#   2. Unauthenticated request (no token) receives HTTP 401 + {error: "unauthorized"}.
RSpec.describe "Auth Guards", type: :request do
  # ─────────────────────────────────────────────────────────────────────────────
  # Shared examples
  # ─────────────────────────────────────────────────────────────────────────────
  shared_examples "a protected endpoint" do |http_method, path_or_proc, params: {}|
    context "when unauthenticated", :skip_auth do
      it "returns 401 with { error: 'unauthorized' }" do
        resolved_path = path_or_proc.is_a?(Proc) ? path_or_proc.call : path_or_proc
        send(http_method, resolved_path, params: params)

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("unauthorized")
      end
    end

    context "when authenticated" do
      it "does not return 401" do
        resolved_path = path_or_proc.is_a?(Proc) ? path_or_proc.call : path_or_proc
        send(http_method, resolved_path, params: params)

        expect(response.status).not_to eq(401)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Public / whitelisted routes (no auth required)
  # ─────────────────────────────────────────────────────────────────────────────
  describe "GET /api/health (public)", :skip_auth do
    it "returns 200 without a token" do
      get "/api/health"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/up (public)", :skip_auth do
    it "returns 200 without a token" do
      get "/api/up"
      expect(response).to have_http_status(:ok)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::CharactersController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::CharactersController" do
    include_examples "a protected endpoint", :get, "/api/v1/characters"

    context "when authenticated" do
      it "GET /api/v1/characters returns 200" do
        get "/api/v1/characters"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::QuestsController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::QuestsController" do
    include_examples "a protected endpoint", :get, "/api/v1/quests"

    context "when authenticated" do
      it "GET /api/v1/quests returns 200" do
        get "/api/v1/quests"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::ArtifactsController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::ArtifactsController" do
    include_examples "a protected endpoint", :get, "/api/v1/artifacts"

    context "when authenticated" do
      it "GET /api/v1/artifacts returns 200" do
        get "/api/v1/artifacts"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::EventsController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::EventsController" do
    include_examples "a protected endpoint", :get, "/api/v1/events"

    context "when authenticated" do
      it "GET /api/v1/events returns 200" do
        get "/api/v1/events"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::LeaderboardController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::LeaderboardController" do
    include_examples "a protected endpoint", :get, "/api/v1/leaderboard"

    context "when authenticated" do
      it "GET /api/v1/leaderboard returns 200" do
        get "/api/v1/leaderboard"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::SimulationController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::SimulationController" do
    include_examples "a protected endpoint", :get, "/api/v1/simulation/status"

    context "when authenticated" do
      it "GET /api/v1/simulation/status returns 200" do
        get "/api/v1/simulation/status"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::PalantirController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::PalantirController" do
    context "when unauthenticated", :skip_auth do
      it "POST /api/v1/palantir/send returns 401" do
        post "/api/v1/palantir/send"
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("unauthorized")
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::Quests::MembersController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::Quests::MembersController" do
    let!(:quest) { create(:quest) }

    context "when unauthenticated", :skip_auth do
      it "POST /api/v1/quests/:id/members returns 401" do
        post "/api/v1/quests/#{quest.id}/members", params: { character_id: 1 }
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("unauthorized")
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Api::V1::Quests::EventsController
  # ─────────────────────────────────────────────────────────────────────────────
  describe "Api::V1::Quests::EventsController" do
    let!(:quest) { create(:quest) }

    include_examples "a protected endpoint", :get,
      -> { "/api/v1/quests/#{FactoryBot.create(:quest).id}/events" }

    context "when authenticated" do
      it "GET /api/v1/quests/:id/events returns 200" do
        get "/api/v1/quests/#{quest.id}/events"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # GraphqlController — open in test/dev, protected in production
  # ─────────────────────────────────────────────────────────────────────────────
  describe "GraphqlController" do
    context "in test environment (auth skipped)" do
      it "POST /graphql returns 200 without a token", :skip_auth do
        post "/graphql",
             params: { query: "{ health }" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
