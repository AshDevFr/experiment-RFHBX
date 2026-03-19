# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — quests queries", type: :request do
  QUESTS_QUERY = <<~GQL
    query {
      quests {
        id title status region questType dangerLevel
      }
    }
  GQL

  describe "quests (list)" do
    context "with no quests in the database" do
      it "returns an empty list" do
        result = gql(QUESTS_QUERY)

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "quests")).to eq([])
      end
    end

    context "with quests in the database" do
      let!(:pending_quest)   { create(:quest, title: "Bag End Departure", status: :pending, region: "Shire") }
      let!(:active_quest)    { create(:quest, title: "Fellowship March", status: :active, region: "Mordor") }
      let!(:completed_quest) { create(:quest, title: "Rivendell Council", status: :completed, region: "Rivendell") }

      it "returns all quests" do
        result = gql(QUESTS_QUERY)

        expect(result["errors"]).to be_nil
        ids = result.dig("data", "quests").map { |q| q["id"] }
        expect(ids).to contain_exactly(pending_quest.id.to_s, active_quest.id.to_s, completed_quest.id.to_s)
      end

      it "filters by status" do
        result = gql("{ quests(status: ACTIVE) { id title } }")

        expect(result["errors"]).to be_nil
        titles = result.dig("data", "quests").map { |q| q["title"] }
        expect(titles).to eq(["Fellowship March"])
      end

      it "filters by region" do
        result = gql("{ quests(region: SHIRE) { id title } }")

        expect(result["errors"]).to be_nil
        titles = result.dig("data", "quests").map { |q| q["title"] }
        expect(titles).to eq(["Bag End Departure"])
      end

      it "can combine status and region filters" do
        result = gql("{ quests(status: ACTIVE, region: MORDOR) { id title } }")

        expect(result["errors"]).to be_nil
        titles = result.dig("data", "quests").map { |q| q["title"] }
        expect(titles).to eq(["Fellowship March"])
      end

      it "returns empty when no quests match filters" do
        result = gql("{ quests(status: FAILED, region: SHIRE) { id title } }")

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "quests")).to eq([])
      end
    end
  end

  describe "quest (single)" do
    context "when the quest exists" do
      let!(:quest) { create(:quest, title: "Destroy the One Ring", status: :active, region: "Mordor") }

      it "returns the quest" do
        result = gql("{ quest(id: #{quest.id}) { id title status region } }")

        expect(result["errors"]).to be_nil
        data = result.dig("data", "quest")
        expect(data["id"]).to eq(quest.id.to_s)
        expect(data["title"]).to eq("Destroy the One Ring")
        expect(data["status"]).to eq("ACTIVE")
        expect(data["region"]).to eq("MORDOR")
      end
    end

    context "when the quest does not exist" do
      it "returns null" do
        result = gql("{ quest(id: 99999) { id title } }")

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "quest")).to be_nil
      end
    end
  end
end
