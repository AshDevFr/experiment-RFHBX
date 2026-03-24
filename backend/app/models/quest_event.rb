# frozen_string_literal: true

class QuestEvent < ApplicationRecord
  enum :event_type, {
    started: "started",
    progress: "progress",
    completed: "completed",
    failed: "failed",
    restarted: "restarted"
  }

  belongs_to :quest

  validates :quest, presence: true
  validates :event_type, presence: true

  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :by_quest, ->(quest_id) { where(quest_id: quest_id) }
  scope :by_quest_title, ->(title) { joins(:quest).where("quests.title ILIKE ?", "%#{title}%") }
end
