# frozen_string_literal: true

FactoryBot.define do
  factory :quest do
    sequence(:title) { |n| "Quest #{n}: #{%w[Destroy\ the\ Ring\ of\ Power Rescue\ the\ Shire Storm\ Helm\'s\ Deep].sample rescue "The Quest"}" }
    description { "An important quest in Middle-earth." }
    status { :pending }
    danger_level { rand(1..10) }
    region { %w[Shire Rivendell Mordor Rohan Gondor Mirkwood].sample }
    progress { 0.0 }
    success_chance { rand(0.1..0.9).round(2) }
    quest_type { :campaign }
    campaign_order { nil }
    attempts { 0 }

    trait :active do
      status { :active }
      attempts { 1 }
    end

    trait :completed do
      status { :completed }
      progress { 1.0 }
    end

    trait :failed do
      status { :failed }
    end

    trait :random_quest do
      quest_type { :random }
    end

    trait :with_campaign_order do
      sequence(:campaign_order) { |n| n }
    end
  end
end
