# frozen_string_literal: true

module Mutations
  module Characters
    class UpdateCharacter < BaseMutation
      description "Update an existing character"

      argument :id, ID, required: true
      argument :input, Types::Input::CharacterInputType, required: true

      field :character, Types::CharacterType, null: true
      field :errors, [String], null: false

      def resolve(id:, input:)
        character = Character.find(id)
        if character.update(input.to_h.compact)
          { character: character, errors: [] }
        else
          { character: nil, errors: character.errors.full_messages }
        end
      rescue ActiveRecord::RecordNotFound
        { character: nil, errors: ["Character not found: #{id}"] }
      rescue ActiveRecord::RecordInvalid => e
        { character: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
