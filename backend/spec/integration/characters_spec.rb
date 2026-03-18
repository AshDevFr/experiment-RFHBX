# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Characters", type: :request do
  path "/api/v1/characters" do
    get "List all characters" do
      tags "Characters"
      operationId "listCharacters"
      produces "application/json"
      description "Returns a paginated list of all characters, ordered by name."

      parameter name: :page, in: :query, schema: { type: :integer, example: 1 },
                required: false, description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, schema: { type: :integer, example: 25 },
                required: false, description: "Results per page (max: 100, default: 25)"

      response "200", "characters retrieved" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Character" }
        before { create_list(:character, 2) }
        run_test!
      end
    end

    post "Create a character" do
      tags "Characters"
      operationId "createCharacter"
      consumes "application/json"
      produces "application/json"
      description "Creates a new character in the simulation."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:character],
        properties: {
          character: { "$ref" => "#/components/schemas/CharacterInput" }
        }
      }

      response "201", "character created" do
        schema "$ref" => "#/components/schemas/Character"
        let(:body) do
          {
            character: {
              name: "Aragorn",
              race: "Human",
              realm: "Gondor",
              title: "Ranger of the North",
              level: 20,
              xp: 5000,
              strength: 18,
              wisdom: 14,
              endurance: 16
            }
          }
        end
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
        let(:body) { { character: { name: "", race: "", level: 0, strength: 0, wisdom: 0, endurance: 0 } } }
        run_test!
      end
    end
  end

  path "/api/v1/characters/{id}" do
    parameter name: :id, in: :path, schema: { type: :integer }, required: true,
              description: "Character ID", example: 1

    get "Get a character" do
      tags "Characters"
      operationId "getCharacter"
      produces "application/json"
      description "Returns a single character with their quests and artifacts."

      response "200", "character found" do
        schema "$ref" => "#/components/schemas/CharacterDetail"
        let(:id) { create(:character).id }
        run_test!
      end

      response "404", "character not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        run_test!
      end
    end

    patch "Update a character" do
      tags "Characters"
      operationId "updateCharacter"
      consumes "application/json"
      produces "application/json"
      description "Updates an existing character's attributes."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:character],
        properties: {
          character: { "$ref" => "#/components/schemas/CharacterInput" }
        }
      }

      response "200", "character updated" do
        schema "$ref" => "#/components/schemas/Character"
        let(:id) { create(:character).id }
        let(:body) { { character: { name: "Boromir", realm: "Gondor", title: "Captain of Gondor" } } }
        run_test!
      end

      response "404", "character not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        let(:body) { { character: { name: "Boromir" } } }
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
        let(:id) { create(:character).id }
        let(:body) { { character: { name: "" } } }
        run_test!
      end
    end

    delete "Delete a character" do
      tags "Characters"
      operationId "deleteCharacter"
      description "Permanently removes a character from the simulation."

      response "204", "character deleted" do
        let(:id) { create(:character).id }
        run_test!
      end

      response "404", "character not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
