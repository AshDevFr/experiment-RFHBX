# frozen_string_literal: true

module Mutations
  module Quests
    class UpdateQuest < BaseMutation
      description "Update an existing quest"

      argument :id, ID, required: true
      argument :input, Types::Input::QuestInputType, required: true

      field :quest, Types::QuestType, null: true
      field :errors, [String], null: false

      def resolve(id:, input:)
        quest = Quest.find(id)
        if quest.update(input.to_h.compact)
          { quest: quest, errors: [] }
        else
          { quest: nil, errors: quest.errors.full_messages }
        end
      rescue ActiveRecord::RecordNotFound
        { quest: nil, errors: ["Quest not found: #{id}"] }
      rescue ActiveRecord::RecordInvalid => e
        { quest: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
