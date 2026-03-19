# frozen_string_literal: true

module Mutations
  module Quests
    class DeleteQuest < BaseMutation
      description "Delete a quest"

      argument :id, ID, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(id:)
        quest = Quest.find(id)
        quest.destroy
        { success: true, errors: [] }
      rescue ActiveRecord::RecordNotFound
        { success: false, errors: ["Quest not found: #{id}"] }
      end
    end
  end
end
