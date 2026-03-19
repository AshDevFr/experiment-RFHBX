# frozen_string_literal: true

module Mutations
  module SimulationConfigs
    class UpdateSimulationConfig < BaseMutation
      description "Update the simulation configuration (singleton)"

      argument :input, Types::Input::SimulationConfigInputType, required: true

      field :simulation_config, Types::SimulationConfigType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        config = SimulationConfig.current
        if config.update(input.to_h.compact)
          { simulation_config: config, errors: [] }
        else
          { simulation_config: nil, errors: config.errors.full_messages }
        end
      rescue ActiveRecord::RecordInvalid => e
        { simulation_config: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
