# frozen_string_literal: true

module Api
  module V1
    class EventsController < ApplicationController
      # GET /api/v1/events
      def index
        events = QuestEvent.all.order(created_at: :desc)
        events = events.where(event_type: params[:event_type]) if params[:event_type].present?
        events = events.where(quest_id: params[:quest_id]) if params[:quest_id].present?
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
