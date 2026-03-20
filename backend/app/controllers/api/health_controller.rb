# frozen_string_literal: true

module Api
  class HealthController < ApplicationController
    skip_before_action :authenticate_request!

    # GET /api/health
    def show
      render json: {
        status: "ok",
        version: Rails.application.config.version,
        environment: Rails.env
      }, status: :ok
    end
  end
end
