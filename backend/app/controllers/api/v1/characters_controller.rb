# frozen_string_literal: true

module Api
  module V1
    class CharactersController < ApplicationController
      before_action :set_character, only: %i[show update destroy]

      # GET /api/v1/characters
      def index
        characters = paginate(Character.includes(:artifacts).order(:name))
        render json: characters.map { |c| c.as_json.merge("artifact_count" => c.artifacts.size) }
      end

      # GET /api/v1/characters/:id
      def show
        render json: character_detail(@character)
      end

      # POST /api/v1/characters
      def create
        character = Character.new(character_params)
        if character.save
          render json: character, status: :created
        else
          render json: { errors: character.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/characters/:id
      def update
        if @character.update(character_params)
          render json: @character
        else
          render json: { errors: @character.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/characters/:id
      def destroy
        @character.destroy
        head :no_content
      end

      private

      def set_character
        @character = Character.find(params[:id])
      end

      def character_params
        params.require(:character).permit(
          :name, :race, :realm, :title, :ring_bearer,
          :level, :xp, :strength, :wisdom, :endurance, :status
        )
      end

      def character_detail(character)
        character.as_json.merge(
          "quests"    => character.quests.as_json(only: %i[id title status danger_level]),
          "artifacts" => character.artifacts.as_json(only: %i[id name artifact_type power corrupted stat_bonus])
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
