# frozen_string_literal: true

module Api
  module V1
    class QuestsController < ApplicationController
      before_action :set_quest, only: %i[show update destroy]

      # GET /api/v1/quests
      def index
        quests = Quest.all.order(:title)
        quests = quests.where(status: params[:status]) if params[:status].present?
        render json: paginate(quests)
      end

      # GET /api/v1/quests/:id
      def show
        render json: quest_detail(@quest)
      end

      # POST /api/v1/quests
      def create
        quest = Quest.new(quest_params)
        if quest.save
          render json: quest, status: :created
        else
          render json: { errors: quest.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/quests/:id
      def update
        if @quest.update(quest_params)
          render json: @quest
        else
          render json: { errors: @quest.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/quests/:id
      def destroy
        @quest.destroy
        head :no_content
      end

      private

      def set_quest
        @quest = Quest.find(params[:id])
      end

      def quest_params
        params.require(:quest).permit(
          :title, :description, :status, :danger_level,
          :region, :progress, :success_chance, :quest_type,
          :campaign_order, :attempts
        )
      end

      def quest_detail(quest)
        quest.as_json.merge(
          "members" => quest.characters.as_json(only: %i[id name race level status]),
          "success_chance" => quest.success_chance&.to_f
        )
      end

      def paginate(scope)
        page = [params.fetch(:page, 1).to_i, 1].max
        per  = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 25
        scope.limit(per).offset((page - 1) * per)
      end
    end
  end
end
