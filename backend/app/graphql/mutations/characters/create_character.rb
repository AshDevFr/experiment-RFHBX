# frozen_string_literal: true

module Mutations
  module Characters
    class CreateCharacter < BaseMutation
      description "Create a new character"

      argument :input, Types::Input::CharacterInputType, required: true

      field :character, Types::CharacterType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        character = Character.new(input.to_h.compact)
        if character.save
          { character: character, errors: [] }
        else
          { character: nil, errors: character.errors.full_messages }
        end
      rescue ActiveRecord::RecordInvalid => e
        { character: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
