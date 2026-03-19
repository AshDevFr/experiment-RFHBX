# frozen_string_literal: true

module Types
  module Input
    class ArtifactInputType < Types::BaseInputObject
      description "Input for creating or updating an artifact"

      argument :name, String, required: true
      argument :artifact_type, String, required: true
      argument :power, String, required: false
      argument :corrupted, Boolean, required: false
      argument :stat_bonus, GraphQL::Types::JSON, required: false
      argument :character_id, ID, required: false
    end
  end
end
