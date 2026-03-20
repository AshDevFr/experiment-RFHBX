# frozen_string_literal: true

class EyeOfSauronWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 3

  # Region pool aligned with quest seed data (Issue #31)
  REGIONS = [
    "Mordor", "Moria", "Rohan", "The Shire", "Rivendell",
    "Isengard", "White Mountains", "Wilderness", "Old Forest"
  ].freeze

  GAZE_MESSAGES = [
    "The Eye of Sauron turns toward %<region>s...",
    "Sauron's gaze sweeps across %<region>s, seeking the One Ring.",
    "The lidless Eye lingers on %<region>s, sensing movement.",
    "A great shadow falls over %<region>s as the Eye watches.",
    "The Eye of Sauron peers into %<region>s, its malice unbroken."
  ].freeze

  def perform
    active_quests = Quest.where(status: :active).to_a
    return if active_quests.empty?

    region = select_region(active_quests)
    threat_level = calculate_threat_level(active_quests, region)
    quest = anchor_quest(active_quests, region)

    QuestEvent.create!(
      quest: quest,
      event_type: :progress,
      message: format(GAZE_MESSAGES.sample, region: region),
      data: {
        "region" => region,
        "threat_level" => threat_level
      }
    )

    broadcast_sauron_gaze(region: region, threat_level: threat_level)
  end

  private

  # Select a region weighted by the sum of danger_level of active quests.
  # Regions with higher total danger have proportionally higher probability.
  # Falls back to uniform weighting if no active quests map to a known region.
  def select_region(active_quests)
    weights = REGIONS.each_with_object({}) do |region, hash|
      regional_danger = active_quests
        .select { |q| q.region.to_s == region }
        .sum(&:danger_level)
      hash[region] = regional_danger
    end

    # Fallback: if all known regions have weight 0 (no active quests in pool),
    # give each region equal weight so a region is always chosen.
    weights.transform_values! { 1 } if weights.values.sum.zero?

    weighted_sample(weights)
  end

  # Sample a region using weighted random selection.
  def weighted_sample(weights)
    total = weights.values.sum.to_f
    threshold = rand * total
    cumulative = 0.0

    weights.each do |region, weight|
      cumulative += weight
      return region if threshold < cumulative
    end

    weights.keys.last
  end

  # Sum of danger_level across active quests in the given region, capped at 10.
  # Returns 0 if no active quests are present in the region.
  def calculate_threat_level(active_quests, region)
    regional_danger = active_quests
      .select { |q| q.region.to_s == region }
      .sum(&:danger_level)

    [regional_danger, 10].min
  end

  # Pick the highest-danger active quest in the region to anchor the event.
  # Falls back to the highest-danger active quest overall if the region is empty.
  def anchor_quest(active_quests, region)
    regional = active_quests.select { |q| q.region.to_s == region }
    (regional.any? ? regional : active_quests).max_by(&:danger_level)
  end

  # Broadcast the Sauron gaze event to all connected clients via Action Cable.
  def broadcast_sauron_gaze(region:, threat_level:)
    ActionCable.server.broadcast("sauron_gaze", {
      region: region,
      threat_level: threat_level,
      message: format(GAZE_MESSAGES.sample, region: region),
      watched_at: Time.current.iso8601
    })
  end
end
