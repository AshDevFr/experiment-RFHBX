# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — simulationConfig query", type: :request do
  SIMULATION_CONFIG_QUERY = <<~GQL
    query {
      simulationConfig {
        id mode running
        progressMin progressMax campaignPosition
      }
    }
  GQL

  describe "simulationConfig (singleton)" do
    context "when no SimulationConfig record exists yet" do
      it "auto-creates the singleton and returns it" do
        expect(SimulationConfig.count).to eq(0)

        result = gql(SIMULATION_CONFIG_QUERY)

        expect(result["errors"]).to be_nil
        data = result.dig("data", "simulationConfig")
        expect(data).not_to be_nil
        expect(data["mode"]).to eq("CAMPAIGN")
        expect(data["running"]).to be false
        expect(SimulationConfig.count).to eq(1)
      end
    end

    context "when a SimulationConfig record already exists" do
      let!(:config) do
        create(:simulation_config,
               mode: :random,
               running: true,
               progress_min: 0.05,
               progress_max: 0.2,
               campaign_position: 3)
      end

      it "returns the existing configuration" do
        result = gql(SIMULATION_CONFIG_QUERY)

        expect(result["errors"]).to be_nil
        data = result.dig("data", "simulationConfig")
        expect(data["id"]).to eq(config.id.to_s)
        expect(data["mode"]).to eq("RANDOM")
        expect(data["running"]).to be true
        expect(data["progressMin"]).to be_within(0.001).of(0.05)
        expect(data["progressMax"]).to be_within(0.001).of(0.2)
        expect(data["campaignPosition"]).to eq(3)
      end
    end
  end
end
