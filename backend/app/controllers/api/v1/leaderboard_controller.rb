# frozen_string_literal: true

module Api
  module V1
    class LeaderboardController < ApplicationController
      # GET /api/v1/leaderboard
      def index
        per = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 25
        characters = Character.order(level: :desc, xp: :desc).limit(per)
        render json: characters.as_json(only: %i[id name race level xp status])
      end
    end
  end
end
