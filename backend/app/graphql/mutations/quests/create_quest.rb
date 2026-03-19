# frozen_string_literal: true

module Mutations
  module Quests
    class CreateQuest < BaseMutation
      description "Create a new quest"

      argument :input, Types::Input::QuestInputType, required: true

      field :quest, Types::QuestType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        quest = Quest.new(input.to_h.compact)
        if quest.save
          { quest: quest, errors: [] }
        else
          { quest: nil, errors: quest.errors.full_messages }
        end
      rescue ActiveRecord::RecordInvalid => e
        { quest: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
