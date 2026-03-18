# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Simulation", type: :request do
  path "/api/v1/simulation/status" do
    get "Get simulation status" do
      tags "Simulation"
      operationId "getSimulationStatus"
      produces "application/json"
      description "Returns the current simulation configuration including mode, running state, and position."

      response "200", "simulation status retrieved" do
        schema "$ref" => "#/components/schemas/SimulationConfig"
        run_test!
      end
    end
  end

  path "/api/v1/simulation/start" do
    post "Start the simulation" do
      tags "Simulation"
      operationId "startSimulation"
      produces "application/json"
      description "Starts the simulation engine. Has no effect if already running."

      response "200", "simulation started (or already running)" do
        schema "$ref" => "#/components/schemas/SimulationConfig"
        run_test!
      end
    end
  end

  path "/api/v1/simulation/stop" do
    post "Stop the simulation" do
      tags "Simulation"
      operationId "stopSimulation"
      produces "application/json"
      description "Stops the simulation engine. Has no effect if already stopped."

      response "200", "simulation stopped (or already stopped)" do
        schema "$ref" => "#/components/schemas/SimulationConfig"
        run_test!
      end
    end
  end

  path "/api/v1/simulation/mode" do
    post "Set simulation mode" do
      tags "Simulation"
      operationId "setSimulationMode"
      consumes "application/json"
      produces "application/json"
      description "Switches the simulation between campaign and random mode."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:mode],
        properties: {
          mode: {
            type: :string,
            enum: %w[campaign random],
            description: "The desired simulation mode",
            example: "campaign"
          }
        }
      }

      response "200", "mode updated" do
        schema "$ref" => "#/components/schemas/SimulationConfig"
        let(:body) { { mode: "random" } }
        run_test!
      end

      response "422", "invalid mode" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:body) { { mode: "turbo" } }
        run_test!
      end
    end
  end

  path "/api/v1/simulation/reset" do
    post "Reset the simulation" do
      tags "Simulation"
      operationId "resetSimulation"
      consumes "application/json"
      produces "application/json"
      description "Resets the simulation to its initial state. Requires explicit confirmation."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:confirm],
        properties: {
          confirm: {
            type: :boolean,
            description: "Must be true to confirm the reset",
            example: true
          }
        }
      }

      response "200", "simulation reset" do
        schema "$ref" => "#/components/schemas/SimulationConfig"
        let(:body) { { confirm: true } }
        run_test!
      end

      response "422", "confirmation missing or false" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:body) { { confirm: false } }
        run_test!
      end
    end
  end
end
