# frozen_string_literal: true

module Types
  module Input
    class SimulationConfigInputType < Types::BaseInputObject
      description "Input for updating the simulation configuration"

      argument :mode, Types::SimulationModeEnum, required: false
      argument :running, Boolean, required: false
      argument :progress_min, Float, required: false
      argument :progress_max, Float, required: false
      argument :campaign_position, Integer, required: false
    end
  end
end
