# frozen_string_literal: true

module Api
  module V1
    class SimulationController < ApplicationController
      # GET /api/v1/simulation/status
      def status
        config = SimulationConfig.current
        render json: config.as_json.merge(
          "tick_count" => config.tick_count
        )
      end

      # POST /api/v1/simulation/start
      def start
        config = SimulationConfig.current
        unless config.running?
          config.update!(running: true)
          QuestTickWorker.perform_async
        end
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

        if new_mode == "campaign"
          # Switching to campaign resets to beginning
          config.update!(mode: new_mode, campaign_position: 0)
        else
          config.update!(mode: new_mode)
        end

        render json: config
      end

      # POST /api/v1/simulation/reset
      def reset
        unless params[:confirm].to_s == "true"
          return render json: { error: "Reset requires confirm: true" },
                        status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          # Reset all characters to idle
          Character.where.not(status: :idle).update_all(status: "idle")

          # Reset all quests
          Quest.where(quest_type: :random).destroy_all
          Quest.where(quest_type: :campaign).update_all(
            status: "pending",
            progress: 0.0,
            attempts: 0
          )

          # Clear all events
          QuestEvent.delete_all

          # Reset config
          config = SimulationConfig.current
          config.update!(
            running: false,
            mode: "campaign",
            campaign_position: 0,
            tick_count: 0
          )
        end

        render json: SimulationConfig.current
      end
    end
  end
end
