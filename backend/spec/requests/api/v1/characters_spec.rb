# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Characters", type: :request do
  describe "GET /api/v1/characters" do
    let!(:characters) { create_list(:character, 3) }

    it "returns HTTP 200" do
      get "/api/v1/characters"
      expect(response).to have_http_status(:ok)
    end

    it "returns all characters" do
      get "/api/v1/characters"
      expect(response.parsed_body.length).to eq(3)
    end

    it "paginates results" do
      get "/api/v1/characters", params: { per_page: 2, page: 1 }
      expect(response.parsed_body.length).to eq(2)
    end
  end

  describe "GET /api/v1/characters/:id" do
    let!(:character) { create(:character) }
    let!(:quest) { create(:quest) }
    let!(:artifact) { create(:artifact, character: character) }

    before { create(:quest_membership, character: character, quest: quest) }

    it "returns HTTP 200" do
      get "/api/v1/characters/#{character.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns the character" do
      get "/api/v1/characters/#{character.id}"
      expect(response.parsed_body["id"]).to eq(character.id)
    end

    it "includes nested quests" do
      get "/api/v1/characters/#{character.id}"
      expect(response.parsed_body["quests"]).to be_an(Array)
    end

    it "includes nested artifacts" do
      get "/api/v1/characters/#{character.id}"
      expect(response.parsed_body["artifacts"]).to be_an(Array)
    end

    it "returns 404 for unknown character" do
      get "/api/v1/characters/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/characters" do
    let(:valid_params) do
      {
        character: {
          name: "Gandalf",
          race: "Wizard",
          level: 20,
          xp: 9999,
          strength: 15,
          wisdom: 20,
          endurance: 12
        }
      }
    end

    it "returns HTTP 201 on success" do
      post "/api/v1/characters", params: valid_params
      expect(response).to have_http_status(:created)
    end

    it "creates the character" do
      expect { post "/api/v1/characters", params: valid_params }
        .to change(Character, :count).by(1)
    end

    it "returns 422 when name is missing" do
      post "/api/v1/characters", params: { character: { race: "Elf", level: 1, strength: 5, wisdom: 5, endurance: 5 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns error messages on failure" do
      post "/api/v1/characters", params: { character: { race: "Elf" } }
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/characters/:id" do
    let!(:character) { create(:character) }

    it "returns HTTP 200 on success" do
      patch "/api/v1/characters/#{character.id}", params: { character: { name: "Bilbo" } }
      expect(response).to have_http_status(:ok)
    end

    it "updates the character" do
      patch "/api/v1/characters/#{character.id}", params: { character: { name: "Bilbo" } }
      expect(character.reload.name).to eq("Bilbo")
    end

    it "returns 422 with invalid params" do
      patch "/api/v1/characters/#{character.id}", params: { character: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for unknown character" do
      patch "/api/v1/characters/0", params: { character: { name: "X" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/characters/:id" do
    let!(:character) { create(:character) }

    it "returns HTTP 204" do
      delete "/api/v1/characters/#{character.id}"
      expect(response).to have_http_status(:no_content)
    end

    it "destroys the character" do
      expect { delete "/api/v1/characters/#{character.id}" }
        .to change(Character, :count).by(-1)
    end

    it "returns 404 for unknown character" do
      delete "/api/v1/characters/0"
      expect(response).to have_http_status(:not_found)
    end
  end
end
