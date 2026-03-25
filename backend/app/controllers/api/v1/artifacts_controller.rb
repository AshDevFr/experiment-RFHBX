# frozen_string_literal: true

module Api
  module V1
    class ArtifactsController < ApplicationController
      before_action :set_artifact, only: %i[show update]

      # GET /api/v1/artifacts
      def index
        scope = Artifact.all.order(:name)
        scope = scope.where(character_id: params[:character_id]) if params[:character_id].present?
        artifacts = paginate(scope)
        render json: artifacts
      end

      # GET /api/v1/artifacts/:id
      def show
        render json: artifact_detail(@artifact)
      end

      # POST /api/v1/artifacts
      def create
        artifact = Artifact.new(artifact_params)
        if artifact.save
          render json: artifact, status: :created
        else
          render json: { errors: artifact.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/artifacts/:id
      def update
        if @artifact.update(artifact_params)
          render json: @artifact
        else
          render json: { errors: @artifact.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_artifact
        @artifact = Artifact.find(params[:id])
      end

      def artifact_params
        params.require(:artifact).permit(
          :name, :artifact_type, :power, :corrupted, :character_id, stat_bonus: {}
        )
      end

      def artifact_detail(artifact)
        artifact.as_json.merge(
          "character" => artifact.character&.as_json(only: %i[id name race level status])
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
