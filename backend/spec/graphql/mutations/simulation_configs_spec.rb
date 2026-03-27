# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — simulation config mutations", type: :request do
  describe "updateSimulationConfig" do
    it "updates the simulation config" do
      mutation = <<~GQL
        mutation {
          updateSimulationConfig(input: {
            mode: RANDOM,
            running: true
          }) {
            simulationConfig { id mode running }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateSimulationConfig")
      expect(data["errors"]).to be_empty
      expect(data["simulationConfig"]["mode"]).to eq("RANDOM")
      expect(data["simulationConfig"]["running"]).to be true
    end

    it "creates the config if it does not exist and updates it" do
      SimulationConfig.delete_all

      mutation = <<~GQL
        mutation {
          updateSimulationConfig(input: {
            mode: CAMPAIGN,
            running: false,
            progressMin: 0.01,
            progressMax: 0.1,
            campaignPosition: 0
          }) {
            simulationConfig { id mode running }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateSimulationConfig")
      expect(data["errors"]).to be_empty
      expect(data["simulationConfig"]["mode"]).to eq("CAMPAIGN")
    end
  end
end
