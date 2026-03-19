# frozen_string_literal: true

module Mutations
  module Artifacts
    class AssignArtifact < BaseMutation
      description "Assign or unassign an artifact to/from a character"

      argument :id, ID, required: true
      argument :character_id, ID, required: false

      field :artifact, Types::ArtifactType, null: true
      field :errors, [String], null: false

      def resolve(id:, character_id: nil)
        artifact = Artifact.find(id)
        if artifact.update(character_id: character_id)
          { artifact: artifact, errors: [] }
        else
          { artifact: nil, errors: artifact.errors.full_messages }
        end
      rescue ActiveRecord::RecordNotFound
        { artifact: nil, errors: ["Artifact not found: #{id}"] }
      end
    end
  end
end
