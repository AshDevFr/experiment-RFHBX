# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — character mutations", type: :request do
  describe "createCharacter" do
    it "creates a character with valid input" do
      mutation = <<~GQL
        mutation {
          createCharacter(input: {
            name: "Aragorn",
            race: MAN,
            level: 10,
            xp: 500,
            strength: 15,
            wisdom: 12,
            endurance: 14
          }) {
            character { id name race level }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createCharacter")
      expect(data["errors"]).to be_empty
      expect(data["character"]["name"]).to eq("Aragorn")
      expect(data["character"]["race"]).to eq("MAN")
      expect(data["character"]["level"]).to eq(10)
    end

    it "returns errors for missing required fields (name blank)" do
      mutation = <<~GQL
        mutation {
          createCharacter(input: {
            name: "",
            race: HOBBIT,
            level: 1,
            xp: 0,
            strength: 5,
            wisdom: 5,
            endurance: 5
          }) {
            character { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createCharacter")
      expect(data["errors"]).not_to be_empty
      expect(data["character"]).to be_nil
    end

    it "returns errors for invalid level (must be > 0)" do
      mutation = <<~GQL
        mutation {
          createCharacter(input: {
            name: "Frodo",
            race: HOBBIT,
            level: 0,
            xp: 0,
            strength: 5,
            wisdom: 5,
            endurance: 5
          }) {
            character { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "createCharacter")
      expect(data["errors"]).not_to be_empty
      expect(data["character"]).to be_nil
    end
  end

  describe "updateCharacter" do
    let!(:character) { create(:character, name: "Boromir", race: "Man", level: 5) }

    it "updates a character with valid input" do
      mutation = <<~GQL
        mutation {
          updateCharacter(id: #{character.id}, input: {
            name: "Faramir",
            race: MAN,
            level: 6,
            xp: 100,
            strength: 10,
            wisdom: 10,
            endurance: 10
          }) {
            character { id name level }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateCharacter")
      expect(data["errors"]).to be_empty
      expect(data["character"]["name"]).to eq("Faramir")
      expect(data["character"]["level"]).to eq(6)
    end

    it "returns errors when character is not found" do
      mutation = <<~GQL
        mutation {
          updateCharacter(id: 99999, input: {
            name: "Ghost",
            race: MAN,
            level: 1,
            xp: 0,
            strength: 5,
            wisdom: 5,
            endurance: 5
          }) {
            character { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateCharacter")
      expect(data["errors"]).not_to be_empty
      expect(data["character"]).to be_nil
    end

    it "returns errors for invalid update" do
      mutation = <<~GQL
        mutation {
          updateCharacter(id: #{character.id}, input: {
            name: "",
            race: MAN,
            level: 1,
            xp: 0,
            strength: 5,
            wisdom: 5,
            endurance: 5
          }) {
            character { id }
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "updateCharacter")
      expect(data["errors"]).not_to be_empty
      expect(data["character"]).to be_nil
    end
  end

  describe "deleteCharacter" do
    let!(:character) { create(:character, name: "Saruman") }

    it "deletes an existing character" do
      mutation = <<~GQL
        mutation {
          deleteCharacter(id: #{character.id}) {
            success
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "deleteCharacter")
      expect(data["success"]).to be true
      expect(data["errors"]).to be_empty
      expect(Character.find_by(id: character.id)).to be_nil
    end

    it "returns errors when character is not found" do
      mutation = <<~GQL
        mutation {
          deleteCharacter(id: 99999) {
            success
            errors
          }
        }
      GQL

      result = gql(mutation)

      expect(result["errors"]).to be_nil
      data = result.dig("data", "deleteCharacter")
      expect(data["success"]).to be false
      expect(data["errors"]).not_to be_empty
    end
  end
end
