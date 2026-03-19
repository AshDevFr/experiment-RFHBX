# frozen_string_literal: true

module Types
  module Input
    class CharacterInputType < Types::BaseInputObject
      description "Input for creating or updating a character"

      argument :name, String, required: true
      argument :race, Types::RaceEnum, required: true
      argument :realm, String, required: false
      argument :title, String, required: false
      argument :ring_bearer, Boolean, required: false
      argument :level, Integer, required: false
      argument :xp, Integer, required: false
      argument :strength, Integer, required: false
      argument :wisdom, Integer, required: false
      argument :endurance, Integer, required: false
      argument :status, Types::CharacterStatusEnum, required: false
    end
  end
end
