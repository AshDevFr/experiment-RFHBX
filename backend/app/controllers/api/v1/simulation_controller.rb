# frozen_string_literal: true

module Api
  module V1
    class SimulationController < ApplicationController
      # GET /api/v1/simulation/status
      def status
        render json: SimulationConfig.current
      end

      # POST /api/v1/simulation/start
      def start
        config = SimulationConfig.current
        config.update!(running: true) unless config.running?
        render json: config
      end

      # POST /api/v1/simulation/stop
      def stop
        config = SimulationConfig.current
        config.update!(running: false) if config.running?
        render json: config
      end

      # POST /api/v1/simulation/mode
      def mode
        new_mode = params[:mode].to_s
        unless SimulationConfig.modes.key?(new_mode)
          return render json: { error: "Invalid mode. Must be 'campaign' or 'random'" },
                        status: :unprocessable_entity
        end

        config = SimulationConfig.current
        config.update!(mode: new_mode)
        render json: config
      end

      # POST /api/v1/simulation/reset
      def reset
        unless params[:confirm].to_s == "true"
          return render json: { error: "Reset requires confirm: true" },
                        status: :unprocessable_entity
        end

        config = SimulationConfig.current
        config.update!(
          running: false,
          mode: "campaign",
          campaign_position: 0
        )
        render json: config
      end
    end
  end
end
