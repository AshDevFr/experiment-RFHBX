# frozen_string_literal: true

module Mutations
  module Artifacts
    class UpdateArtifact < BaseMutation
      description "Update an existing artifact"

      argument :id, ID, required: true
      argument :input, Types::Input::ArtifactInputType, required: true

      field :artifact, Types::ArtifactType, null: true
      field :errors, [String], null: false

      def resolve(id:, input:)
        artifact = Artifact.find(id)
        if artifact.update(input.to_h.compact)
          { artifact: artifact, errors: [] }
        else
          { artifact: nil, errors: artifact.errors.full_messages }
        end
      rescue ActiveRecord::RecordNotFound
        { artifact: nil, errors: ["Artifact not found: #{id}"] }
      rescue ActiveRecord::RecordInvalid => e
        { artifact: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
