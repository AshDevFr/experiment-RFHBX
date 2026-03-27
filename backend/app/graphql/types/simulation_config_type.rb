# frozen_string_literal: true

module Types
  class SimulationConfigType < Types::BaseObject
    description "Global simulation configuration (singleton)"

    field :id, ID, null: false
    field :mode, Types::SimulationModeEnum, null: false
    field :running, Boolean, null: false
    field :progress_min, Float, null: false
    field :progress_max, Float, null: false
    field :campaign_position, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
