# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — quest mutations", type: :request do
  describe "createQuest" do
    it "creates a quest with valid input" do
      mutation = <<~GQL
        mutation {
          createQuest(input: {
            title: "Destroy the One Ring",
            dangerLevel: 10,
            questType: CAMPAIGN,
            status: PENDING,
            attempts: 0
          }) {
            quest { id title dangerLevel status }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createQuest")
      expect(data["errors"]).to be_empty
      expect(data["quest"]["title"]).to eq("Destroy the One Ring")
      expect(data["quest"]["dangerLevel"]).to eq(10)
    end

    it "returns errors for missing title" do
      mutation = <<~GQL
        mutation {
          createQuest(input: {
            title: "",
            dangerLevel: 5,
            questType: CAMPAIGN,
            status: PENDING,
            attempts: 0
          }) {
            quest { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createQuest")
      expect(data["errors"]).not_to be_empty
      expect(data["quest"]).to be_nil
    end

    it "returns errors for invalid danger_level" do
      mutation = <<~GQL
        mutation {
          createQuest(input: {
            title: "Bad Quest",
            dangerLevel: 11,
            questType: CAMPAIGN,
            status: PENDING,
            attempts: 0
          }) {
            quest { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createQuest")
      expect(data["errors"]).not_to be_empty
      expect(data["quest"]).to be_nil
    end
  end

  describe "updateQuest" do
    let!(:quest) { create(:quest, title: "Old Quest", danger_level: 3) }

    it "updates a quest with valid input" do
      mutation = <<~GQL
        mutation {
          updateQuest(id: #{quest.id}, input: {
            title: "New Quest Title",
            dangerLevel: 7,
            questType: CAMPAIGN,
            status: ACTIVE,
            attempts: 1
          }) {
            quest { id title dangerLevel status }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateQuest")
      expect(data["errors"]).to be_empty
      expect(data["quest"]["title"]).to eq("New Quest Title")
      expect(data["quest"]["dangerLevel"]).to eq(7)
      expect(data["quest"]["status"]).to eq("ACTIVE")
    end

    it "returns errors when quest is not found" do
      mutation = <<~GQL
        mutation {
          updateQuest(id: 99999, input: {
            title: "Ghost Quest",
            dangerLevel: 5,
            questType: CAMPAIGN,
            status: PENDING,
            attempts: 0
          }) {
            quest { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateQuest")
      expect(data["errors"]).not_to be_empty
      expect(data["quest"]).to be_nil
    end

    it "returns errors for invalid update" do
      mutation = <<~GQL
        mutation {
          updateQuest(id: #{quest.id}, input: {
            title: "",
            dangerLevel: 5,
            questType: CAMPAIGN,
            status: PENDING,
            attempts: 0
          }) {
            quest { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateQuest")
      expect(data["errors"]).not_to be_empty
      expect(data["quest"]).to be_nil
    end
  end

  describe "deleteQuest" do
    let!(:quest) { create(:quest, title: "Doomed Quest") }

    it "deletes an existing quest" do
      mutation = <<~GQL
        mutation {
          deleteQuest(id: #{quest.id}) {
            success
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "deleteQuest")
      expect(data["success"]).to be true
      expect(data["errors"]).to be_empty
      expect(Quest.find_by(id: quest.id)).to be_nil
    end

    it "returns errors when quest is not found" do
      mutation = <<~GQL
        mutation {
          deleteQuest(id: 99999) {
            success
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "deleteQuest")
      expect(data["success"]).to be false
      expect(data["errors"]).not_to be_empty
    end
  end
end
