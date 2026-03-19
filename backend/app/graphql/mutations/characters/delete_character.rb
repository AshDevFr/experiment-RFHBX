# frozen_string_literal: true

module Mutations
  module Characters
    class DeleteCharacter < BaseMutation
      description "Delete a character"

      argument :id, ID, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(id:)
        character = Character.find(id)
        character.destroy
        { success: true, errors: [] }
      rescue ActiveRecord::RecordNotFound
        { success: false, errors: ["Character not found: #{id}"] }
      end
    end
  end
end
