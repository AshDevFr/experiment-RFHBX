# frozen_string_literal: true

FactoryBot.define do
  factory :simulation_config do
    mode { :campaign }
    running { false }
    progress_min { 0.01 }
    progress_max { 0.1 }
    campaign_position { 0 }
    tick_count { 0 }

    trait :running do
      running { true }
    end

    trait :random_mode do
      mode { :random }
    end
  end
end
