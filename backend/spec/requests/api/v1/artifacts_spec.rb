# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Artifacts", type: :request do
  describe "GET /api/v1/artifacts" do
    let!(:artifacts) { create_list(:artifact, 3) }

    it "returns HTTP 200" do
      get "/api/v1/artifacts"
      expect(response).to have_http_status(:ok)
    end

    it "returns all artifacts" do
      get "/api/v1/artifacts"
      expect(response.parsed_body.length).to eq(3)
    end
  end

  describe "GET /api/v1/artifacts/:id" do
    let!(:character) { create(:character) }
    let!(:artifact) { create(:artifact, character: character) }

    it "returns HTTP 200" do
      get "/api/v1/artifacts/#{artifact.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns the artifact" do
      get "/api/v1/artifacts/#{artifact.id}"
      expect(response.parsed_body["id"]).to eq(artifact.id)
    end

    it "includes character holder details" do
      get "/api/v1/artifacts/#{artifact.id}"
      expect(response.parsed_body["character"]).to be_present
      expect(response.parsed_body["character"]["id"]).to eq(character.id)
    end

    it "returns null character for unowned artifact" do
      unowned = create(:artifact, character: nil)
      get "/api/v1/artifacts/#{unowned.id}"
      expect(response.parsed_body["character"]).to be_nil
    end

    it "returns 404 for unknown artifact" do
      get "/api/v1/artifacts/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/artifacts" do
    let(:valid_params) { { artifact: { name: "Sting", artifact_type: "sword" } } }

    it "returns HTTP 201" do
      post "/api/v1/artifacts", params: valid_params
      expect(response).to have_http_status(:created)
    end

    it "creates an artifact" do
      expect { post "/api/v1/artifacts", params: valid_params }
        .to change(Artifact, :count).by(1)
    end

    it "returns 422 when name is missing" do
      post "/api/v1/artifacts", params: { artifact: { artifact_type: "sword" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/artifacts/:id" do
    let!(:artifact) { create(:artifact) }

    it "returns HTTP 200" do
      patch "/api/v1/artifacts/#{artifact.id}", params: { artifact: { name: "Updated Sting" } }
      expect(response).to have_http_status(:ok)
    end

    it "updates the artifact" do
      patch "/api/v1/artifacts/#{artifact.id}", params: { artifact: { name: "Updated Sting" } }
      expect(artifact.reload.name).to eq("Updated Sting")
    end

    it "returns 422 with invalid params" do
      patch "/api/v1/artifacts/#{artifact.id}", params: { artifact: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
