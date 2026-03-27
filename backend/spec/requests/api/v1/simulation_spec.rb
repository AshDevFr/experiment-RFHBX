# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Simulation", type: :request do
  before { SimulationConfig.destroy_all }

  describe "GET /api/v1/simulation/status" do
    it "returns HTTP 200" do
      get "/api/v1/simulation/status"
      expect(response).to have_http_status(:ok)
    end

    it "returns the simulation config with expected fields" do
      get "/api/v1/simulation/status"
      body = response.parsed_body
      expect(body).to include("running", "mode", "campaign_position", "tick_count")
    end

    it "includes tick_count in status response" do
      SimulationConfig.current.update!(tick_count: 42)
      get "/api/v1/simulation/status"
      expect(response.parsed_body["tick_count"]).to eq(42)
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

    it "does not enqueue QuestTickWorker (cron handles scheduling)" do
      expect { post "/api/v1/simulation/start" }.not_to change(QuestTickWorker.jobs, :size)
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

    it "switches to campaign mode and resets campaign_position" do
      SimulationConfig.current.update!(mode: "random", campaign_position: 5)
      post "/api/v1/simulation/mode", params: { mode: "campaign" }
      expect(response.parsed_body["mode"]).to eq("campaign")
      expect(response.parsed_body["campaign_position"]).to eq(0)
    end

    it "returns 422 for invalid mode" do
      post "/api/v1/simulation/mode", params: { mode: "invalid" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/simulation/config" do
    it "returns HTTP 200" do
      patch "/api/v1/simulation/config", params: { progress_min: 0.05 }
      expect(response).to have_http_status(:ok)
    end

    it "updates progress_min and progress_max" do
      patch "/api/v1/simulation/config", params: { progress_min: 0.05, progress_max: 0.2 }
      body = response.parsed_body
      expect(body["progress_min"].to_f).to be_within(0.001).of(0.05)
      expect(body["progress_max"].to_f).to be_within(0.001).of(0.2)
    end

    it "updates mode" do
      patch "/api/v1/simulation/config", params: { mode: "random" }
      expect(response.parsed_body["mode"]).to eq("random")
    end

    it "resets campaign_position when switching to campaign" do
      SimulationConfig.current.update!(mode: "random", campaign_position: 5)
      patch "/api/v1/simulation/config", params: { mode: "campaign" }
      expect(response.parsed_body["campaign_position"]).to eq(0)
    end

    it "returns 422 for invalid mode" do
      patch "/api/v1/simulation/config", params: { mode: "invalid" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "ignores tick_interval_seconds param (no longer a permitted field)" do
      patch "/api/v1/simulation/config", params: { progress_min: 0.05 }
      expect(response).to have_http_status(:ok)
    end

    it "can update multiple fields at once" do
      patch "/api/v1/simulation/config",
            params: { progress_min: 0.02, progress_max: 0.15, mode: "random" }
      body = response.parsed_body
      expect(body["mode"]).to eq("random")
    end
  end

  describe "POST /api/v1/simulation/reset" do
    it "returns HTTP 200 with confirm: true" do
      post "/api/v1/simulation/reset", params: { confirm: true }
      expect(response).to have_http_status(:ok)
    end

    it "resets simulation state" do
      config = SimulationConfig.current
      config.update!(running: true, mode: "random", campaign_position: 5, tick_count: 100)
      post "/api/v1/simulation/reset", params: { confirm: true }
      body = response.parsed_body
      expect(body["running"]).to be(false)
      expect(body["mode"]).to eq("campaign")
      expect(body["campaign_position"]).to eq(0)
      expect(body["tick_count"]).to eq(0)
    end

    it "resets all characters to idle" do
      char = create(:character, status: :on_quest)
      post "/api/v1/simulation/reset", params: { confirm: true }
      expect(char.reload.status).to eq("idle")
    end

    it "resets campaign quests to pending" do
      quest = create(:quest, quest_type: :campaign, status: :completed, progress: 1.0, attempts: 2)
      post "/api/v1/simulation/reset", params: { confirm: true }
      quest.reload
      expect(quest.status).to eq("pending")
      expect(quest.progress.to_f).to eq(0.0)
      expect(quest.attempts).to eq(0)
    end

    it "deletes random quests" do
      create(:quest, quest_type: :random)
      expect { post "/api/v1/simulation/reset", params: { confirm: true } }
        .to change { Quest.where(quest_type: :random).count }.to(0)
    end

    it "clears all quest events" do
      quest = create(:quest)
      create(:quest_event, quest: quest)
      expect { post "/api/v1/simulation/reset", params: { confirm: true } }
        .to change(QuestEvent, :count).to(0)
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
