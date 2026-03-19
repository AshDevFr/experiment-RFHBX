# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — questMemberships queries", type: :request do
  QUEST_MEMBERSHIPS_QUERY = <<~GQL
    query {
      questMemberships {
        id role
        character { id name }
        quest { id title }
      }
    }
  GQL

  describe "questMemberships (list)" do
    context "with no memberships in the database" do
      it "returns an empty list" do
        result = gql(QUEST_MEMBERSHIPS_QUERY)

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "questMemberships")).to eq([])
      end
    end

    context "with memberships in the database" do
      let!(:frodo)       { create(:character, name: "Frodo") }
      let!(:sam)         { create(:character, name: "Sam") }
      let!(:ring_quest)  { create(:quest, title: "Destroy the Ring") }
      let!(:shire_quest) { create(:quest, title: "Protect the Shire") }
      let!(:mem1)        { create(:quest_membership, character: frodo, quest: ring_quest, role: "leader") }
      let!(:mem2)        { create(:quest_membership, character: sam, quest: ring_quest, role: "scout") }
      let!(:mem3)        { create(:quest_membership, character: sam, quest: shire_quest, role: "warrior") }

      it "returns all memberships" do
        result = gql(QUEST_MEMBERSHIPS_QUERY)

        expect(result["errors"]).to be_nil
        ids = result.dig("data", "questMemberships").map { |m| m["id"] }
        expect(ids).to contain_exactly(mem1.id.to_s, mem2.id.to_s, mem3.id.to_s)
      end

      it "resolves nested character and quest associations without N+1" do
        result = gql(QUEST_MEMBERSHIPS_QUERY)

        expect(result["errors"]).to be_nil
        memberships = result.dig("data", "questMemberships")
        frodo_mem = memberships.find { |m| m["character"]["name"] == "Frodo" }
        expect(frodo_mem["quest"]["title"]).to eq("Destroy the Ring")
        expect(frodo_mem["role"]).to eq("leader")
      end

      it "filters by quest_id" do
        result = gql("{ questMemberships(questId: #{ring_quest.id}) { id character { name } } }")

        expect(result["errors"]).to be_nil
        names = result.dig("data", "questMemberships").map { |m| m["character"]["name"] }
        expect(names).to contain_exactly("Frodo", "Sam")
      end

      it "filters by character_id" do
        result = gql("{ questMemberships(characterId: #{sam.id}) { id quest { title } } }")

        expect(result["errors"]).to be_nil
        titles = result.dig("data", "questMemberships").map { |m| m["quest"]["title"] }
        expect(titles).to contain_exactly("Destroy the Ring", "Protect the Shire")
      end

      it "can combine quest_id and character_id filters" do
        result = gql("{ questMemberships(questId: #{ring_quest.id}, characterId: #{sam.id}) { id role } }")

        expect(result["errors"]).to be_nil
        memberships = result.dig("data", "questMemberships")
        expect(memberships.size).to eq(1)
        expect(memberships.first["role"]).to eq("scout")
      end

      it "returns empty when no memberships match the filter" do
        result = gql("{ questMemberships(questId: 99999) { id } }")

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "questMemberships")).to eq([])
      end
    end
  end
end
