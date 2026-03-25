# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Chaos", type: :request do
  # -----------------------------------------------------------------------
  # wound_character
  # -----------------------------------------------------------------------
  describe "POST /api/v1/chaos/wound_character" do
    context "when there are on_quest characters" do
      let!(:quest) { Quest.create!(title: "Journey to Mordor", danger_level: 8, status: :active, region: "Mordor") }
      let!(:character) do
        Character.create!(name: "Boromir", race: "Human", strength: 15, wisdom: 10, endurance: 14, status: :on_quest)
      end
      let!(:membership) { QuestMembership.create!(quest: quest, character: character) }

      it "returns HTTP 200" do
        post "/api/v1/chaos/wound_character"
        expect(response).to have_http_status(:ok)
      end

      it "sets the character status to fallen" do
        post "/api/v1/chaos/wound_character"
        expect(character.reload.status).to eq("fallen")
      end

      it "removes the character from their quest membership" do
        expect { post "/api/v1/chaos/wound_character" }.to change(QuestMembership, :count).by(-1)
      end

      it "creates a failed QuestEvent noting the casualty" do
        expect { post "/api/v1/chaos/wound_character" }.to change(QuestEvent, :count).by(1)
        event = QuestEvent.last
        expect(event.event_type).to eq("failed")
        expect(event.quest).to eq(quest)
        expect(event.data["chaos_action"]).to eq("wound_character")
        expect(event.data["character_name"]).to eq("Boromir")
      end

      it "returns the affected character data" do
        post "/api/v1/chaos/wound_character"
        body = response.parsed_body
        expect(body["affected"]["name"]).to eq("Boromir")
        expect(body["affected"]["status"]).to eq("fallen")
      end
    end

    context "when no characters are on a quest" do
      let!(:idle_character) do
        Character.create!(name: "Gandalf", race: "Wizard", strength: 12, wisdom: 20, endurance: 15, status: :idle)
      end

      it "returns HTTP 422" do
        post "/api/v1/chaos/wound_character"
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error message" do
        post "/api/v1/chaos/wound_character"
        expect(response.parsed_body["error"]).to match(/no characters/i)
      end
    end

    context "when all characters are fallen" do
      let!(:fallen) do
        Character.create!(name: "Theoden", race: "Human", strength: 14, wisdom: 12, endurance: 13, status: :fallen)
      end

      it "returns HTTP 422" do
        post "/api/v1/chaos/wound_character"
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # -----------------------------------------------------------------------
  # fail_quest
  # -----------------------------------------------------------------------
  describe "POST /api/v1/chaos/fail_quest" do
    context "when there are active quests" do
      let!(:quest) do
        Quest.create!(title: "Defend Helm's Deep", danger_level: 7, status: :active, region: "Rohan", progress: 0.65)
      end
      let!(:char1) do
        Character.create!(name: "Aragorn", race: "Human", strength: 18, wisdom: 14, endurance: 16, status: :on_quest)
      end
      let!(:char2) do
        Character.create!(name: "Legolas", race: "Elf", strength: 14, wisdom: 16, endurance: 14, status: :on_quest)
      end

      before do
        QuestMembership.create!(quest: quest, character: char1)
        QuestMembership.create!(quest: quest, character: char2)
      end

      it "returns HTTP 200" do
        post "/api/v1/chaos/fail_quest"
        expect(response).to have_http_status(:ok)
      end

      it "marks the quest as failed with progress 0" do
        post "/api/v1/chaos/fail_quest"
        quest.reload
        expect(quest.status).to eq("failed")
        expect(quest.progress.to_f).to eq(0.0)
      end

      it "resets member characters to idle" do
        post "/api/v1/chaos/fail_quest"
        expect(char1.reload.status).to eq("idle")
        expect(char2.reload.status).to eq("idle")
      end

      it "creates a failed QuestEvent" do
        expect { post "/api/v1/chaos/fail_quest" }.to change(QuestEvent, :count).by(1)
        event = QuestEvent.last
        expect(event.event_type).to eq("failed")
        expect(event.quest).to eq(quest)
        expect(event.data["chaos_action"]).to eq("fail_quest")
      end

      it "returns the affected quest data with members_reset count" do
        post "/api/v1/chaos/fail_quest"
        body = response.parsed_body
        expect(body["affected"]["title"]).to eq("Defend Helm's Deep")
        expect(body["affected"]["status"]).to eq("failed")
        expect(body["affected"]["progress"]).to eq(0.0)
        expect(body["affected"]["members_reset"]).to eq(2)
      end
    end

    context "when no active quests exist" do
      let!(:quest) { Quest.create!(title: "Completed Quest", danger_level: 3, status: :completed) }

      it "returns HTTP 422" do
        post "/api/v1/chaos/fail_quest"
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error message" do
        post "/api/v1/chaos/fail_quest"
        expect(response.parsed_body["error"]).to match(/no active quests/i)
      end
    end
  end

  # -----------------------------------------------------------------------
  # spike_threat
  # -----------------------------------------------------------------------
  describe "POST /api/v1/chaos/spike_threat" do
    context "when there are active quests" do
      let!(:quest) do
        Quest.create!(title: "Scout Moria", danger_level: 6, status: :active, region: "Moria")
      end

      it "returns HTTP 200" do
        post "/api/v1/chaos/spike_threat"
        expect(response).to have_http_status(:ok)
      end

      it "returns threat_level 10" do
        post "/api/v1/chaos/spike_threat"
        body = response.parsed_body
        expect(body["affected"]["threat_level"]).to eq(10)
      end

      it "returns the region from the active quest" do
        post "/api/v1/chaos/spike_threat"
        body = response.parsed_body
        expect(body["affected"]["region"]).to be_present
      end

      it "creates a progress QuestEvent" do
        expect { post "/api/v1/chaos/spike_threat" }.to change(QuestEvent, :count).by(1)
        event = QuestEvent.last
        expect(event.event_type).to eq("progress")
        expect(event.data["chaos_action"]).to eq("spike_threat")
        expect(event.data["threat_level"]).to eq(10)
      end
    end

    context "when no active quests exist" do
      it "returns HTTP 422" do
        post "/api/v1/chaos/spike_threat"
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error message" do
        post "/api/v1/chaos/spike_threat"
        expect(response.parsed_body["error"]).to match(/no active quests/i)
      end
    end
  end

  # -----------------------------------------------------------------------
  # stop_simulation
  # -----------------------------------------------------------------------
  describe "POST /api/v1/chaos/stop_simulation" do
    before { SimulationConfig.destroy_all }

    context "when the simulation is running" do
      before { SimulationConfig.current.update!(running: true) }

      it "returns HTTP 200" do
        post "/api/v1/chaos/stop_simulation"
        expect(response).to have_http_status(:ok)
      end

      it "stops the simulation" do
        post "/api/v1/chaos/stop_simulation"
        expect(SimulationConfig.current.running?).to be(false)
      end

      it "returns the halt message" do
        post "/api/v1/chaos/stop_simulation"
        body = response.parsed_body
        expect(body["affected"]["simulation_running"]).to be(false)
        expect(body["affected"]["message"]).to include("Eye of Sauron loses focus")
      end
    end

    context "when the simulation is not running" do
      before { SimulationConfig.current.update!(running: false) }

      it "returns HTTP 422" do
        post "/api/v1/chaos/stop_simulation"
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error message" do
        post "/api/v1/chaos/stop_simulation"
        expect(response.parsed_body["error"]).to match(/not running/i)
      end
    end
  end
end
