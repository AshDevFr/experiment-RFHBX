# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Chaos", type: :request do
  # -------------------------------------------------------------------
  # wound_character
  # -------------------------------------------------------------------
  path "/api/v1/chaos/wound_character" do
    post "Wound a random on-quest character" do
      tags "Chaos"
      operationId "chaosWoundCharacter"
      produces "application/json"
      description "Sets a random on_quest character to fallen, removes them from their " \
                  "active quest membership, and creates a failed QuestEvent noting the casualty."

      response "200", "character wounded" do
        schema "$ref" => "#/components/schemas/ChaosWoundCharacterResult"

        before do
          quest = Quest.create!(title: "March to Mordor", danger_level: 9, status: :active, region: "Mordor")
          char  = Character.create!(name: "Boromir", race: "Human", strength: 15, wisdom: 10, endurance: 14, status: :on_quest)
          QuestMembership.create!(quest: quest, character: char)
        end

        run_test!
      end

      response "422", "no eligible characters" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        run_test!
      end
    end
  end

  # -------------------------------------------------------------------
  # fail_quest
  # -------------------------------------------------------------------
  path "/api/v1/chaos/fail_quest" do
    post "Fail a random active quest" do
      tags "Chaos"
      operationId "chaosFailQuest"
      produces "application/json"
      description "Immediately fails a random active quest, resets progress to 0, " \
                  "returns member characters to idle, and creates a failed QuestEvent."

      response "200", "quest failed" do
        schema "$ref" => "#/components/schemas/ChaosFailQuestResult"

        before do
          quest = Quest.create!(title: "Defend Helm's Deep", danger_level: 7, status: :active, region: "Rohan", progress: 0.5)
          char  = Character.create!(name: "Aragorn", race: "Human", strength: 18, wisdom: 14, endurance: 16, status: :on_quest)
          QuestMembership.create!(quest: quest, character: char)
        end

        run_test!
      end

      response "422", "no active quests" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        run_test!
      end
    end
  end

  # -------------------------------------------------------------------
  # spike_threat
  # -------------------------------------------------------------------
  path "/api/v1/chaos/spike_threat" do
    post "Spike threat level to maximum" do
      tags "Chaos"
      operationId "chaosSpikeThreat"
      produces "application/json"
      description "Publishes a threat-level spike (level 10) via the sauron_gaze channel. " \
                  "Decays naturally on the next EyeOfSauronWorker tick."

      response "200", "threat spiked" do
        schema "$ref" => "#/components/schemas/ChaosSpikeResult"

        before do
          Quest.create!(title: "Scout Moria", danger_level: 6, status: :active, region: "Moria")
        end

        run_test!
      end

      response "422", "no active quests" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        run_test!
      end
    end
  end

  # -------------------------------------------------------------------
  # stop_simulation
  # -------------------------------------------------------------------
  path "/api/v1/chaos/stop_simulation" do
    post "Stop the simulation via chaos injection" do
      tags "Chaos"
      operationId "chaosStopSimulation"
      produces "application/json"
      description "Stops the simulation and broadcasts a Sauron event: " \
                  "'The Eye of Sauron loses focus — simulation halted.'"

      response "200", "simulation stopped" do
        schema "$ref" => "#/components/schemas/ChaosStopSimulationResult"

        before do
          SimulationConfig.destroy_all
          SimulationConfig.current.update!(running: true)
        end

        run_test!
      end

      response "422", "simulation not running" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        before do
          SimulationConfig.destroy_all
          SimulationConfig.current.update!(running: false)
        end

        run_test!
      end
    end
  end
end
