# frozen_string_literal: true

class PalantirJob < ApplicationJob
  queue_as :default

  def perform(message)
    # Stub: creates a QuestEvent on the most recent active quest
    quest = Quest.where(status: :active).order(created_at: :desc).first
    return unless quest

    QuestEvent.create!(
      quest: quest,
      event_type: :started,
      message: "Palantir message received: #{message}"
    )
  end
end
