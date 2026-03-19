# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — artifact mutations", type: :request do
  describe "createArtifact" do
    it "creates an artifact with valid input" do
      mutation = <<~GQL
        mutation {
          createArtifact(input: {
            name: "Anduril",
            artifactType: "sword",
            corrupted: false
          }) {
            artifact { id name artifactType corrupted }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createArtifact")
      expect(data["errors"]).to be_empty
      expect(data["artifact"]["name"]).to eq("Anduril")
      expect(data["artifact"]["artifactType"]).to eq("sword")
      expect(data["artifact"]["corrupted"]).to be false
    end

    it "returns errors for missing name" do
      mutation = <<~GQL
        mutation {
          createArtifact(input: {
            name: "",
            artifactType: "ring"
          }) {
            artifact { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createArtifact")
      expect(data["errors"]).not_to be_empty
      expect(data["artifact"]).to be_nil
    end

    it "returns errors for missing artifact_type" do
      mutation = <<~GQL
        mutation {
          createArtifact(input: {
            name: "Mystery Item",
            artifactType: ""
          }) {
            artifact { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createArtifact")
      expect(data["errors"]).not_to be_empty
      expect(data["artifact"]).to be_nil
    end
  end

  describe "updateArtifact" do
    let!(:artifact) { create(:artifact, name: "Old Sword", artifact_type: "sword", corrupted: false) }

    it "updates an artifact with valid input" do
      mutation = <<~GQL
        mutation {
          updateArtifact(id: #{artifact.id}, input: {
            name: "Glamdring",
            artifactType: "sword",
            corrupted: false
          }) {
            artifact { id name artifactType }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateArtifact")
      expect(data["errors"]).to be_empty
      expect(data["artifact"]["name"]).to eq("Glamdring")
    end

    it "returns errors when artifact is not found" do
      mutation = <<~GQL
        mutation {
          updateArtifact(id: 99999, input: {
            name: "Ghost Sword",
            artifactType: "sword"
          }) {
            artifact { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateArtifact")
      expect(data["errors"]).not_to be_empty
      expect(data["artifact"]).to be_nil
    end
  end

  describe "assignArtifact" do
    let!(:character) { create(:character, name: "Gandalf") }
    let!(:artifact)  { create(:artifact, name: "Glamdring", artifact_type: "sword") }

    it "assigns an artifact to a character" do
      mutation = <<~GQL
        mutation {
          assignArtifact(id: #{artifact.id}, characterId: #{character.id}) {
            artifact { id name character { id name } }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "assignArtifact")
      expect(data["errors"]).to be_empty
      expect(data["artifact"]["character"]["name"]).to eq("Gandalf")
    end

    it "unassigns an artifact from a character" do
      artifact.update!(character: character)

      mutation = <<~GQL
        mutation {
          assignArtifact(id: #{artifact.id}) {
            artifact { id name character { id } }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "assignArtifact")
      expect(data["errors"]).to be_empty
      expect(data["artifact"]["character"]).to be_nil
    end

    it "returns errors when artifact is not found" do
      mutation = <<~GQL
        mutation {
          assignArtifact(id: 99999, characterId: #{character.id}) {
            artifact { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "assignArtifact")
      expect(data["errors"]).not_to be_empty
      expect(data["artifact"]).to be_nil
    end
  end
end
