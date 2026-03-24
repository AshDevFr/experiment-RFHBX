# frozen_string_literal: true

module Api
  module V1
    class QuestsController < ApplicationController
      before_action :set_quest, only: %i[show update destroy]

      # GET /api/v1/quests
      def index
        quests = Quest.includes(:characters).all.order(:title)
        quests = quests.where(status: params[:status]) if params[:status].present?
        render json: paginate(quests).map { |q| quest_detail(q) }
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
        was_pending = @quest.pending?
        if @quest.update(quest_params)
          assign_idle_characters(@quest) if was_pending && @quest.active?
          render json: quest_detail(@quest)
        else
          render json: { errors: @quest.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/quests/:id
      def destroy
        @quest.destroy
        head :no_content
      end

      # POST /api/v1/quests/reset
      def reset
        unless params[:confirm].to_s == "true"
          return render json: { error: "Reset requires confirm: true" },
                        status: :unprocessable_entity
        end

        Quest.transaction do
          QuestMembership.delete_all
          Quest.update_all(status: "pending", progress: 0.0, attempts: 0)
          Character.update_all(status: "idle", level: 0, xp: 0)
        end

        render json: { message: "All quests reset to pending state", count: Quest.count }
      end

      # POST /api/v1/quests/randomize
      def randomize
        available_characters = Character.where(status: %w[idle on_quest]).to_a
        quests = Quest.all.to_a

        Quest.transaction do
          QuestMembership.delete_all
          Character.update_all(status: "idle")

          assigned_ids = []
          quests.each do |quest|
            count = rand(2..4)
            assigned = available_characters.sample(count)
            assigned.each do |character|
              QuestMembership.create!(quest: quest, character: character)
              assigned_ids << character.id
            end
          end
          Character.where(id: assigned_ids.uniq).update_all(status: "on_quest")
        end

        render json: { message: "Quest assignments randomized", count: quests.count }
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
          "success_chance" => quest.success_chance&.to_f,
          "progress" => quest.progress.to_f
        )
      end

      def assign_idle_characters(quest)
        idle_characters = Character.where(status: :idle).limit(4)
        idle_characters.each do |character|
          QuestMembership.find_or_create_by!(quest: quest, character: character) do |m|
            m.role = "Adventurer"
          end
          character.update!(status: :on_quest)
        end
      end

      def paginate(scope)
        page = [params.fetch(:page, 1).to_i, 1].max
        per  = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 25
        scope.limit(per).offset((page - 1) * per)
      end
    end
  end
end
