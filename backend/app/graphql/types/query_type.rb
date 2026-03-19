# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    description "The query root of this schema"

    field :health, String, null: false, description: "Returns ok when the GraphQL endpoint is alive"

    # ---------------------------------------------------------------------------
    # Characters
    # ---------------------------------------------------------------------------

    field :characters, [Types::CharacterType], null: false,
          description: "List all characters, with optional filters" do
      argument :race, String, required: false, description: "Filter by race (e.g. Hobbit, Elf, Dwarf, Man, Wizard)"
      argument :status, Types::CharacterStatusEnum, required: false, description: "Filter by status"
      argument :fellowship_member, Boolean, required: false,
               description: "When true, return only characters with at least one quest membership; " \
                            "when false, return only characters with no quest memberships"
    end

    field :character, Types::CharacterType, null: true,
          description: "Fetch a single character by ID (returns null if not found)" do
      argument :id, ID, required: true, description: "The character's ID"
    end

    # ---------------------------------------------------------------------------
    # Quests
    # ---------------------------------------------------------------------------

    field :quests, [Types::QuestType], null: false,
          description: "List all quests, with optional filters" do
      argument :status, Types::QuestStatusEnum, required: false, description: "Filter by quest status"
      argument :region, Types::RegionEnum, required: false, description: "Filter by region"
    end

    field :quest, Types::QuestType, null: true,
          description: "Fetch a single quest by ID (returns null if not found)" do
      argument :id, ID, required: true, description: "The quest's ID"
    end

    # ---------------------------------------------------------------------------
    # Artifacts
    # ---------------------------------------------------------------------------

    field :artifacts, [Types::ArtifactType], null: false,
          description: "List all artifacts, with optional filters" do
      argument :artifact_type, String, required: false, description: "Filter by artifact type"
      argument :corrupted, Boolean, required: false, description: "Filter by corruption status"
    end

    field :artifact, Types::ArtifactType, null: true,
          description: "Fetch a single artifact by ID (returns null if not found)" do
      argument :id, ID, required: true, description: "The artifact's ID"
    end

    # ---------------------------------------------------------------------------
    # Quest Memberships
    # ---------------------------------------------------------------------------

    field :quest_memberships, [Types::QuestMembershipType], null: false,
          description: "List quest memberships, optionally filtered by quest or character" do
      argument :quest_id, ID, required: false, description: "Filter by quest ID"
      argument :character_id, ID, required: false, description: "Filter by character ID"
    end

    # ---------------------------------------------------------------------------
    # Simulation Config
    # ---------------------------------------------------------------------------

    field :simulation_config, Types::SimulationConfigType, null: false,
          description: "Fetch the current simulation configuration (singleton)"

    # ---------------------------------------------------------------------------
    # Resolvers
    # ---------------------------------------------------------------------------

    def health
      "ok"
    end

    def characters(race: nil, status: nil, fellowship_member: nil)
      scope = Character.all
      scope = scope.where(race: race) if race
      scope = scope.where(status: status) if status
      unless fellowship_member.nil?
        if fellowship_member
          scope = scope.joins(:quest_memberships).distinct
        else
          scope = scope.left_joins(:quest_memberships).where(quest_memberships: { id: nil })
        end
      end
      scope
    end

    def character(id:)
      Character.find_by(id: id)
    end

    def quests(status: nil, region: nil)
      scope = Quest.all
      scope = scope.where(status: status) if status
      scope = scope.where(region: region) if region
      scope
    end

    def quest(id:)
      Quest.find_by(id: id)
    end

    def artifacts(artifact_type: nil, corrupted: nil)
      scope = Artifact.includes(:character)
      scope = scope.where(artifact_type: artifact_type) if artifact_type
      scope = scope.where(corrupted: corrupted) unless corrupted.nil?
      scope
    end

    def artifact(id:)
      Artifact.includes(:character).find_by(id: id)
    end

    def quest_memberships(quest_id: nil, character_id: nil)
      scope = QuestMembership.includes(:character, :quest)
      scope = scope.where(quest_id: quest_id) if quest_id
      scope = scope.where(character_id: character_id) if character_id
      scope
    end

    def simulation_config
      SimulationConfig.current
    end
  end
end
