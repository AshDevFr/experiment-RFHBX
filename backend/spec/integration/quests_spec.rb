# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Quests", type: :request do
  path "/api/v1/quests" do
    get "List all quests" do
      tags "Quests"
      operationId "listQuests"
      produces "application/json"
      description "Returns a paginated list of quests. Optionally filter by status."

      parameter name: :status, in: :query,
                schema: { type: :string, enum: %w[pending active completed failed] },
                required: false, description: "Filter quests by status"
      parameter name: :page, in: :query, schema: { type: :integer, example: 1 },
                required: false, description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, schema: { type: :integer, example: 25 },
                required: false, description: "Results per page (max: 100, default: 25)"

      response "200", "quests retrieved" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Quest" }
        before { create_list(:quest, 2) }
        run_test!
      end
    end

    post "Create a quest" do
      tags "Quests"
      operationId "createQuest"
      consumes "application/json"
      produces "application/json"
      description "Creates a new quest in the simulation."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:quest],
        properties: {
          quest: { "$ref" => "#/components/schemas/QuestInput" }
        }
      }

      response "201", "quest created" do
        schema "$ref" => "#/components/schemas/Quest"
        let(:body) do
          {
            quest: {
              title: "Destroy the One Ring",
              description: "Cast the One Ring into the fires of Mount Doom.",
              danger_level: 10,
              region: "Mordor",
              quest_type: "campaign",
              campaign_order: 1
            }
          }
        end
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
        let(:body) { { quest: { title: "", danger_level: 0 } } }
        run_test!
      end
    end
  end

  path "/api/v1/quests/{id}" do
    parameter name: :id, in: :path, schema: { type: :integer }, required: true,
              description: "Quest ID", example: 1

    get "Get a quest" do
      tags "Quests"
      operationId "getQuest"
      produces "application/json"
      description "Returns a single quest with its member list and success chance."

      response "200", "quest found" do
        schema "$ref" => "#/components/schemas/QuestDetail"
        let(:id) { create(:quest).id }
        run_test!
      end

      response "404", "quest not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        run_test!
      end
    end

    patch "Update a quest" do
      tags "Quests"
      operationId "updateQuest"
      consumes "application/json"
      produces "application/json"
      description "Updates an existing quest's attributes."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:quest],
        properties: {
          quest: { "$ref" => "#/components/schemas/QuestInput" }
        }
      }

      response "200", "quest updated" do
        schema "$ref" => "#/components/schemas/Quest"
        let(:id) { create(:quest).id }
        let(:body) { { quest: { title: "The Battle of Pelennor Fields", region: "Gondor", danger_level: 9 } } }
        run_test!
      end

      response "404", "quest not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        let(:body) { { quest: { title: "Phantom Quest", danger_level: 1 } } }
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
        let(:id) { create(:quest).id }
        let(:body) { { quest: { title: "" } } }
        run_test!
      end

      response "422", "activating a memberless quest is rejected" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
        let(:id) { create(:quest, status: :pending).id }
        let(:body) { { quest: { status: "active" } } }
        run_test!
      end
    end

    delete "Delete a quest" do
      tags "Quests"
      operationId "deleteQuest"
      description "Permanently removes a quest from the simulation."

      response "204", "quest deleted" do
        let(:id) { create(:quest).id }
        run_test!
      end

      response "404", "quest not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        run_test!
      end
    end
  end

  path "/api/v1/quests/{quest_id}/members" do
    parameter name: :quest_id, in: :path, schema: { type: :integer }, required: true,
              description: "Quest ID", example: 1

    post "Add a member to a quest" do
      tags "Quest Members"
      operationId "addQuestMember"
      consumes "application/json"
      produces "application/json"
      description "Adds a character to a quest. A character may only be on one active quest at a time."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:character_id],
        properties: {
          character_id: { type: :integer, description: "ID of the character to add", example: 1 },
          role: { type: :string, description: "Optional role for the character on this quest", example: "guide" }
        }
      }

      response "201", "member added" do
        let(:quest_id) { create(:quest, :active).id }
        let(:body) { { character_id: create(:character).id } }
        run_test!
      end

      response "422", "character already on an active quest" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:other_quest) { create(:quest, :active) }
        let(:the_character) { create(:character) }
        let(:quest_id) do
          create(:quest_membership, quest: other_quest, character: the_character)
          create(:quest, :active).id
        end
        let(:body) { { character_id: the_character.id } }
        run_test!
      end
    end
  end

  path "/api/v1/quests/{quest_id}/members/{character_id}" do
    parameter name: :quest_id, in: :path, schema: { type: :integer }, required: true,
              description: "Quest ID", example: 1
    parameter name: :character_id, in: :path, schema: { type: :integer }, required: true,
              description: "Character ID to remove", example: 1

    delete "Remove a member from a quest" do
      tags "Quest Members"
      operationId "removeQuestMember"
      description "Removes a character from a quest."

      response "204", "member removed" do
        let(:the_quest) { create(:quest) }
        let(:the_character) { create(:character) }
        let(:quest_id) do
          create(:quest_membership, quest: the_quest, character: the_character)
          the_quest.id
        end
        let(:character_id) { the_character.id }
        run_test!
      end
    end
  end

  path "/api/v1/quests/{quest_id}/events" do
    parameter name: :quest_id, in: :path, schema: { type: :integer }, required: true,
              description: "Quest ID", example: 1
    parameter name: :page, in: :query, schema: { type: :integer, example: 1 },
              required: false, description: "Page number (default: 1)"
    parameter name: :per_page, in: :query, schema: { type: :integer, example: 25 },
              required: false, description: "Results per page (max: 100, default: 25)"

    get "List events for a quest" do
      tags "Quest Events"
      operationId "listQuestEvents"
      produces "application/json"
      description "Returns quest events in reverse chronological order."

      response "200", "events retrieved" do
        schema type: :array, items: { "$ref" => "#/components/schemas/QuestEvent" }
        let(:the_quest) { create(:quest) }
        let(:quest_id) do
          create_list(:quest_event, 2, quest: the_quest)
          the_quest.id
        end
        run_test!
      end

      response "404", "quest not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:quest_id) { 0 }
        run_test!
      end
    end
  end
end
