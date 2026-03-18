# frozen_string_literal: true

module Api
  module V1
    module Quests
      class MembersController < ApplicationController
        before_action :set_quest

        # POST /api/v1/quests/:quest_id/members
        def create
          character = Character.find(member_params[:character_id])

          if on_active_quest?(character)
            return render json: { error: "Character is already on an active quest" },
                          status: :unprocessable_entity
          end

          membership = @quest.quest_memberships.build(
            character: character,
            role: member_params[:role]
          )

          if membership.save
            render json: membership, status: :created
          else
            render json: { errors: membership.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/quests/:quest_id/members/:character_id
        def destroy
          membership = @quest.quest_memberships.find_by!(character_id: params[:character_id])
          membership.destroy
          head :no_content
        end

        private

        def set_quest
          @quest = Quest.find(params[:quest_id])
        end

        def member_params
          if params[:member].present?
            params.require(:member).permit(:character_id, :role)
          else
            params.permit(:character_id, :role)
          end
        end

        def on_active_quest?(character)
          QuestMembership.joins(:quest)
                         .where(character_id: character.id)
                         .where(quests: { status: "active" })
                         .exists?
        end
      end
    end
  end
end
