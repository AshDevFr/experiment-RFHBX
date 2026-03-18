# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Simulation", type: :request do
  before { SimulationConfig.destroy_all }

  describe "GET /api/v1/simulation/status" do
    it "returns HTTP 200" do
      get "/api/v1/simulation/status"
      expect(response).to have_http_status(:ok)
    end

    it "returns the simulation config" do
      get "/api/v1/simulation/status"
      expect(response.parsed_body).to include("running", "mode")
    end
  end

  describe "POST /api/v1/simulation/start" do
    it "returns HTTP 200" do
      post "/api/v1/simulation/start"
      expect(response).to have_http_status(:ok)
    end

    it "sets running to true" do
      post "/api/v1/simulation/start"
      expect(response.parsed_body["running"]).to be(true)
    end

    it "is idempotent when already running" do
      config = SimulationConfig.current
      config.update!(running: true)
      post "/api/v1/simulation/start"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["running"]).to be(true)
    end
  end

  describe "POST /api/v1/simulation/stop" do
    it "returns HTTP 200" do
      post "/api/v1/simulation/stop"
      expect(response).to have_http_status(:ok)
    end

    it "sets running to false" do
      config = SimulationConfig.current
      config.update!(running: true)
      post "/api/v1/simulation/stop"
      expect(response.parsed_body["running"]).to be(false)
    end

    it "is idempotent when already stopped" do
      post "/api/v1/simulation/stop"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["running"]).to be(false)
    end
  end

  describe "POST /api/v1/simulation/mode" do
    it "returns HTTP 200" do
      post "/api/v1/simulation/mode", params: { mode: "random" }
      expect(response).to have_http_status(:ok)
    end

    it "switches to random mode" do
      post "/api/v1/simulation/mode", params: { mode: "random" }
      expect(response.parsed_body["mode"]).to eq("random")
    end

    it "switches to campaign mode" do
      SimulationConfig.current.update!(mode: "random")
      post "/api/v1/simulation/mode", params: { mode: "campaign" }
      expect(response.parsed_body["mode"]).to eq("campaign")
    end

    it "returns 422 for invalid mode" do
      post "/api/v1/simulation/mode", params: { mode: "invalid" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/simulation/reset" do
    it "returns HTTP 200 with confirm: true" do
      post "/api/v1/simulation/reset", params: { confirm: true }
      expect(response).to have_http_status(:ok)
    end

    it "resets simulation state" do
      config = SimulationConfig.current
      config.update!(running: true, mode: "random", campaign_position: 5)
      post "/api/v1/simulation/reset", params: { confirm: true }
      expect(response.parsed_body["running"]).to be(false)
      expect(response.parsed_body["mode"]).to eq("campaign")
      expect(response.parsed_body["campaign_position"]).to eq(0)
    end

    it "returns 422 without confirm" do
      post "/api/v1/simulation/reset"
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 with confirm: false" do
      post "/api/v1/simulation/reset", params: { confirm: false }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
