# frozen_string_literal: true

module Api
  module V1
    module Quests
      class EventsController < ApplicationController
        # GET /api/v1/quests/:quest_id/events
        def index
          quest = Quest.find(params[:quest_id])
          events = quest.quest_events.order(created_at: :desc)
          render json: paginate(events)
        end

        private

        def paginate(scope)
          page = [params.fetch(:page, 1).to_i, 1].max
          per  = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 25
          scope.limit(per).offset((page - 1) * per)
        end
      end
    end
  end
end
