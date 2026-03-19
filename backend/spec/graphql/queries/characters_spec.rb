# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — characters queries", type: :request do
  CHARACTERS_QUERY = <<~GQL
    query {
      characters {
        id name race status ringBearer
      }
    }
  GQL

  describe "characters (list)" do
    context "with no characters in the database" do
      it "returns an empty list" do
        result = gql(CHARACTERS_QUERY)

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "characters")).to eq([])
      end
    end

    context "with characters in the database" do
      let!(:frodo)  { create(:character, name: "Frodo", race: "Hobbit", status: :idle) }
      let!(:gandalf) { create(:character, name: "Gandalf", race: "Wizard", status: :on_quest) }
      let!(:legolas) { create(:character, name: "Legolas", race: "Elf", status: :idle) }

      it "returns all characters" do
        result = gql(CHARACTERS_QUERY)

        expect(result["errors"]).to be_nil
        ids = result.dig("data", "characters").map { |c| c["id"] }
        expect(ids).to contain_exactly(frodo.id.to_s, gandalf.id.to_s, legolas.id.to_s)
      end

      it "filters by race" do
        result = gql('{ characters(race: "Hobbit") { id name } }')

        expect(result["errors"]).to be_nil
        names = result.dig("data", "characters").map { |c| c["name"] }
        expect(names).to eq(["Frodo"])
      end

      it "filters by status" do
        result = gql('{ characters(status: ON_QUEST) { id name } }')

        expect(result["errors"]).to be_nil
        names = result.dig("data", "characters").map { |c| c["name"] }
        expect(names).to eq(["Gandalf"])
      end

      context "with fellowship_member filter" do
        let!(:quest)      { create(:quest) }
        let!(:membership) { create(:quest_membership, character: frodo, quest: quest) }

        it "returns only characters with quest memberships when fellowship_member is true" do
          result = gql("{ characters(fellowshipMember: true) { id name } }")

          expect(result["errors"]).to be_nil
          names = result.dig("data", "characters").map { |c| c["name"] }
          expect(names).to eq(["Frodo"])
        end

        it "returns only characters without quest memberships when fellowship_member is false" do
          result = gql("{ characters(fellowshipMember: false) { id name } }")

          expect(result["errors"]).to be_nil
          names = result.dig("data", "characters").map { |c| c["name"] }
          expect(names).to contain_exactly("Gandalf", "Legolas")
        end
      end

      it "can combine race and status filters" do
        create(:character, name: "Sam", race: "Hobbit", status: :on_quest)
        result = gql('{ characters(race: "Hobbit", status: ON_QUEST) { id name } }')

        expect(result["errors"]).to be_nil
        names = result.dig("data", "characters").map { |c| c["name"] }
        expect(names).to eq(["Sam"])
      end
    end
  end

  describe "character (single)" do
    context "when the character exists" do
      let!(:aragorn) { create(:character, name: "Aragorn", race: "Man") }

      it "returns the character" do
        result = gql("{ character(id: #{aragorn.id}) { id name race } }")

        expect(result["errors"]).to be_nil
        data = result.dig("data", "character")
        expect(data["id"]).to eq(aragorn.id.to_s)
        expect(data["name"]).to eq("Aragorn")
        expect(data["race"]).to eq("MAN")
      end
    end

    context "when the character does not exist" do
      it "returns null" do
        result = gql("{ character(id: 99999) { id name } }")

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "character")).to be_nil
      end
    end
  end
end
