# frozen_string_literal: true

class SimulationConfig < ApplicationRecord
  enum :mode, { campaign: "campaign", random: "random" }, default: "campaign"

  validates :tick_interval_seconds, numericality: { greater_than: 0 }
  validates :tick_count, numericality: { greater_than_or_equal_to: 0 }
  validate :only_one_instance

  def self.current
    first_or_create!(
      mode: "campaign",
      running: false,
      tick_interval_seconds: 60,
      progress_min: 0.01,
      progress_max: 0.1,
      campaign_position: 0,
      tick_count: 0
    )
  end

  private

  def only_one_instance
    return if SimulationConfig.where.not(id: id).none?

    errors.add(:base, "only one SimulationConfig can exist")
  end
end
