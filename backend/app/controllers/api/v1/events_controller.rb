# frozen_string_literal: true

module Api
  module V1
    class EventsController < ApplicationController
      # GET /api/v1/events
      def index
        events = QuestEvent.includes(:quest).order(created_at: :desc)
        events = events.by_event_type(params[:event_type]) if params[:event_type].present?
        events = events.by_quest(params[:quest_id]) if params[:quest_id].present?
        events = events.by_quest_title(params[:quest_title]) if params[:quest_title].present?

        total = events.count
        page  = [params.fetch(:page, 1).to_i, 1].max
        per   = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 25

        paged = events.limit(per).offset((page - 1) * per)

        render json: {
          events: paged.map { |e| serialize_event(e) },
          meta: {
            total: total,
            page: page,
            per_page: per,
            total_pages: total.zero? ? 1 : (total.to_f / per).ceil
          }
        }
      end

      private

      def serialize_event(event)
        {
          id: event.id,
          quest_id: event.quest_id,
          quest_title: event.quest.title,
          event_type: event.event_type,
          message: event.message,
          data: event.data,
          created_at: event.created_at
        }
      end
    end
  end
end
