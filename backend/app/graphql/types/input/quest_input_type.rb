# frozen_string_literal: true

module Types
  module Input
    class QuestInputType < Types::BaseInputObject
      description "Input for creating or updating a quest"

      argument :title, String, required: true
      argument :description, String, required: false
      argument :status, Types::QuestStatusEnum, required: false
      argument :danger_level, Integer, required: false
      argument :region, Types::RegionEnum, required: false
      argument :progress, Float, required: false
      argument :success_chance, Float, required: false
      argument :quest_type, Types::QuestTypeEnum, required: false
      argument :campaign_order, Integer, required: false
      argument :attempts, Integer, required: false
    end
  end
end
