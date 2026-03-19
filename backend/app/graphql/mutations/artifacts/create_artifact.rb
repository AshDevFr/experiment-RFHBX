# frozen_string_literal: true

module Mutations
  module Artifacts
    class CreateArtifact < BaseMutation
      description "Create a new artifact"

      argument :input, Types::Input::ArtifactInputType, required: true

      field :artifact, Types::ArtifactType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        artifact = Artifact.new(input.to_h.compact)
        if artifact.save
          { artifact: artifact, errors: [] }
        else
          { artifact: nil, errors: artifact.errors.full_messages }
        end
      rescue ActiveRecord::RecordInvalid => e
        { artifact: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
