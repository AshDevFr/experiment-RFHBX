# frozen_string_literal: true

# Handles artifact drops for party members on quest success.
#
# Each character has a configurable DROP_CHANCE (default 30%) of receiving
# one LOTR-canon artifact. The artifact is assigned a random stat_bonus
# drawn from { strength, wisdom, endurance } with a value between 1 and
# the quest's danger_level. A QuestEvent of type :artifact_found is created
# per drop and broadcast over ActionCable.
#
# Usage:
#   ArtifactDropService.call(quest)
class ArtifactDropService
  DROP_CHANCE = 0.30

  STAT_ATTRIBUTES = %w[strength wisdom endurance].freeze

  LOTR_ARTIFACTS = [
    { name: "Mithril Shirt",         artifact_type: "armour"    },
    { name: "Sting",                 artifact_type: "sword"     },
    { name: "Glamdring",             artifact_type: "sword"     },
    { name: "Phial of Galadriel",    artifact_type: "relic"     },
    { name: "Horn of Gondor",        artifact_type: "relic"     },
    { name: "Elven Cloak",           artifact_type: "cloak"     },
    { name: "Lembas Bread",          artifact_type: "provision" },
    { name: "And\u00FAril",               artifact_type: "sword"     },
    { name: "Narya",                 artifact_type: "ring"      },
    { name: "Nenya",                 artifact_type: "ring"      },
    { name: "Vilya",                 artifact_type: "ring"      },
    { name: "Bow of Lothl\u00F3rien",     artifact_type: "bow"       },
    { name: "Dwarven Shield",        artifact_type: "shield"    },
    { name: "Staff of Gandalf",      artifact_type: "staff"     },
    { name: "Blade of the Barrow-wights", artifact_type: "sword" }
  ].freeze

  ONE_RING = { name: "One Ring", artifact_type: "ring" }.freeze

  def self.call(quest)
    new(quest).call
  end

  def initialize(quest)
    @quest = quest
  end

  def call
    @quest.characters.each do |character|
      next unless rand < DROP_CHANCE

      drop_artifact(character)
    end
  end

  private

  def drop_artifact(character)
    template = pick_artifact_template
    stat     = STAT_ATTRIBUTES.sample
    value    = rand(1..[(@quest.danger_level || 1), 1].max)

    artifact = Artifact.create!(
      character:     character,
      name:          template[:name],
      artifact_type: template[:artifact_type],
      stat_bonus:    { stat => value }
    )

    event = QuestEvent.create!(
      quest:      @quest,
      event_type: :artifact_found,
      message:    "#{character.name} found #{artifact.name}!",
      data:       {
        "character_id"   => character.id,
        "character_name" => character.name,
        "artifact_id"    => artifact.id,
        "artifact_name"  => artifact.name,
        "stat_bonus"     => artifact.stat_bonus
      }
    )

    QuestEventBroadcaster.broadcast(event)
  end

  def pick_artifact_template
    # The One Ring has a small chance to drop at maximum danger level
    return ONE_RING if @quest.danger_level >= 10 && rand < 0.10

    LOTR_ARTIFACTS.sample
  end
end
