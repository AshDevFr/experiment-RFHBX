# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    description "The mutation root of this schema"

    # Characters
    field :create_character, mutation: Mutations::Characters::CreateCharacter
    field :update_character, mutation: Mutations::Characters::UpdateCharacter
    field :delete_character, mutation: Mutations::Characters::DeleteCharacter

    # Quests
    field :create_quest, mutation: Mutations::Quests::CreateQuest
    field :update_quest, mutation: Mutations::Quests::UpdateQuest
    field :delete_quest, mutation: Mutations::Quests::DeleteQuest

    # Artifacts
    field :create_artifact, mutation: Mutations::Artifacts::CreateArtifact
    field :update_artifact, mutation: Mutations::Artifacts::UpdateArtifact
    field :assign_artifact, mutation: Mutations::Artifacts::AssignArtifact

    # SimulationConfig
    field :update_simulation_config, mutation: Mutations::SimulationConfigs::UpdateSimulationConfig
  end
end
