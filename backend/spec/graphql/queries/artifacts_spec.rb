# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — artifacts queries", type: :request do
  ARTIFACTS_QUERY = <<~GQL
    query {
      artifacts {
        id name artifactType corrupted
      }
    }
  GQL

  describe "artifacts (list)" do
    context "with no artifacts in the database" do
      it "returns an empty list" do
        result = gql(ARTIFACTS_QUERY)

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "artifacts")).to eq([])
      end
    end

    context "with artifacts in the database" do
      let!(:ring)   { create(:artifact, name: "One Ring", artifact_type: "ring", corrupted: true) }
      let!(:sting)  { create(:artifact, name: "Sting", artifact_type: "sword", corrupted: false) }
      let!(:staff)  { create(:artifact, name: "Gandalf's Staff", artifact_type: "staff", corrupted: false) }

      it "returns all artifacts" do
        result = gql(ARTIFACTS_QUERY)

        expect(result["errors"]).to be_nil
        ids = result.dig("data", "artifacts").map { |a| a["id"] }
        expect(ids).to contain_exactly(ring.id.to_s, sting.id.to_s, staff.id.to_s)
      end

      it "filters by artifact_type" do
        result = gql('{ artifacts(artifactType: "ring") { id name } }')

        expect(result["errors"]).to be_nil
        names = result.dig("data", "artifacts").map { |a| a["name"] }
        expect(names).to eq(["One Ring"])
      end

      it "filters by corrupted = true" do
        result = gql("{ artifacts(corrupted: true) { id name } }")

        expect(result["errors"]).to be_nil
        names = result.dig("data", "artifacts").map { |a| a["name"] }
        expect(names).to eq(["One Ring"])
      end

      it "filters by corrupted = false" do
        result = gql("{ artifacts(corrupted: false) { id name } }")

        expect(result["errors"]).to be_nil
        names = result.dig("data", "artifacts").map { |a| a["name"] }
        expect(names).to contain_exactly("Sting", "Gandalf's Staff")
      end

      it "can combine artifact_type and corrupted filters" do
        result = gql('{ artifacts(artifactType: "ring", corrupted: true) { id name } }')

        expect(result["errors"]).to be_nil
        names = result.dig("data", "artifacts").map { |a| a["name"] }
        expect(names).to eq(["One Ring"])
      end

      context "when artifact has an owner (character association)" do
        let!(:frodo)    { create(:character, name: "Frodo") }
        let!(:artifact) { create(:artifact, name: "Phial of Galadriel", artifact_type: "amulet", character: frodo) }

        it "returns the character nested inside the artifact without N+1" do
          result = gql("{ artifacts { id name character { id name } } }")

          expect(result["errors"]).to be_nil
          phial = result.dig("data", "artifacts").find { |a| a["name"] == "Phial of Galadriel" }
          expect(phial["character"]["name"]).to eq("Frodo")
        end
      end
    end
  end

  describe "artifact (single)" do
    context "when the artifact exists" do
      let!(:artifact) { create(:artifact, name: "Glamdring", artifact_type: "sword", corrupted: false) }

      it "returns the artifact" do
        result = gql("{ artifact(id: #{artifact.id}) { id name artifactType corrupted } }")

        expect(result["errors"]).to be_nil
        data = result.dig("data", "artifact")
        expect(data["id"]).to eq(artifact.id.to_s)
        expect(data["name"]).to eq("Glamdring")
        expect(data["artifactType"]).to eq("sword")
        expect(data["corrupted"]).to be false
      end
    end

    context "when the artifact does not exist" do
      it "returns null" do
        result = gql("{ artifact(id: 99999) { id name } }")

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "artifact")).to be_nil
      end
    end
  end
end
