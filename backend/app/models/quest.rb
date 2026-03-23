# frozen_string_literal: true

class Quest < ApplicationRecord
  enum :status, { pending: "pending", active: "active", completed: "completed", failed: "failed" }, default: "pending"
  enum :quest_type, { campaign: "campaign", random: "random" }, default: "campaign"

  has_many :quest_memberships, dependent: :destroy
  has_many :characters, through: :quest_memberships
  has_many :quest_events, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :danger_level, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :attempts, numericality: { greater_than_or_equal_to: 0 }

  def as_json(options = {})
    super(options).tap do |json|
      json["progress"] = progress.to_f
      json["success_chance"] = success_chance&.to_f
    end
  end
end
