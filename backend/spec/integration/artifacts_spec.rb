# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Artifacts", type: :request do
  path "/api/v1/artifacts" do
    get "List all artifacts" do
      tags "Artifacts"
      operationId "listArtifacts"
      produces "application/json"
      description "Returns a paginated list of all artifacts, ordered by name."

      parameter name: :page, in: :query, schema: { type: :integer, example: 1 },
                required: false, description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, schema: { type: :integer, example: 25 },
                required: false, description: "Results per page (max: 100, default: 25)"

      response "200", "artifacts retrieved" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Artifact" }
        before { create_list(:artifact, 2) }
        run_test!
      end
    end

    post "Create an artifact" do
      tags "Artifacts"
      operationId "createArtifact"
      consumes "application/json"
      produces "application/json"
      description "Creates a new artifact. Artifacts may optionally be assigned to a character."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:artifact],
        properties: {
          artifact: { "$ref" => "#/components/schemas/ArtifactInput" }
        }
      }

      response "201", "artifact created" do
        schema "$ref" => "#/components/schemas/Artifact"
        let(:body) do
          {
            artifact: {
              name: "The One Ring",
              artifact_type: "ring",
              power: 100,
              corrupted: true,
              stat_bonus: { "wisdom" => -10, "charisma" => 50 }
            }
          }
        end
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
        let(:body) { { artifact: { name: "", artifact_type: "" } } }
        run_test!
      end
    end
  end

  path "/api/v1/artifacts/{id}" do
    parameter name: :id, in: :path, schema: { type: :integer }, required: true,
              description: "Artifact ID", example: 1

    get "Get an artifact" do
      tags "Artifacts"
      operationId "getArtifact"
      produces "application/json"
      description "Returns a single artifact with its owning character (if assigned)."

      response "200", "artifact found" do
        schema "$ref" => "#/components/schemas/ArtifactDetail"
        let(:id) { create(:artifact).id }
        run_test!
      end

      response "404", "artifact not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        run_test!
      end
    end

    patch "Update an artifact" do
      tags "Artifacts"
      operationId "updateArtifact"
      consumes "application/json"
      produces "application/json"
      description "Updates an existing artifact. Artifacts cannot be destroyed once created."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:artifact],
        properties: {
          artifact: { "$ref" => "#/components/schemas/ArtifactInput" }
        }
      }

      response "200", "artifact updated" do
        schema "$ref" => "#/components/schemas/Artifact"
        let(:id) { create(:artifact).id }
        let(:body) do
          {
            artifact: {
              name: "Narya the Ring of Fire",
              artifact_type: "ring",
              power: 85,
              corrupted: false
            }
          }
        end
        run_test!
      end

      response "404", "artifact not found" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:id) { 0 }
        let(:body) { { artifact: { name: "Nenya", artifact_type: "ring", power: 80 } } }
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/ValidationErrors"
        let(:id) { create(:artifact).id }
        let(:body) { { artifact: { name: "", artifact_type: "" } } }
        run_test!
      end
    end
  end
end
