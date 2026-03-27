# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "Mordor's Edge API",
        version: "v1",
        description: "API for the Mordor's Edge fantasy RPG simulation — manage characters, " \
                     "quests, artifacts, and the simulation engine."
      },
      servers: [
        { url: "/", description: "Default server" }
      ],
      components: {
        schemas: {
          Character: {
            type: :object,
            description: "A character in the simulation",
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: "Aragorn" },
              race: { type: :string, example: "Human" },
              realm: { type: :string, nullable: true, example: "Gondor" },
              title: { type: :string, nullable: true, example: "Ranger of the North" },
              ring_bearer: { type: :boolean, example: false },
              level: { type: :integer, example: 20 },
              xp: { type: :integer, example: 5000 },
              strength: { type: :integer, example: 18 },
              wisdom: { type: :integer, example: 14 },
              endurance: { type: :integer, example: 16 },
              status: { type: :string, enum: %w[idle on_quest fallen], example: "idle" },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" },
              artifact_count: { type: :integer, example: 2, description: "Number of artifacts owned by this character" }
            },
            required: %w[id name race level xp strength wisdom endurance status]
          },

          CharacterDetail: {
            allOf: [
              { "$ref" => "#/components/schemas/Character" },
              {
                type: :object,
                description: "Character with nested quests and artifacts",
                properties: {
                  quests: {
                    type: :array,
                    items: { "$ref" => "#/components/schemas/QuestSummary" }
                  },
                  artifacts: {
                    type: :array,
                    items: { "$ref" => "#/components/schemas/ArtifactSummary" }
                  }
                }
              }
            ]
          },

          CharacterSummary: {
            type: :object,
            description: "Abbreviated character info used in nested responses",
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: "Legolas" },
              race: { type: :string, example: "Elf" },
              level: { type: :integer, example: 15 },
              status: { type: :string, enum: %w[idle on_quest fallen], example: "on_quest" }
            },
            required: %w[id name race level status]
          },

          CharacterInput: {
            type: :object,
            description: "Payload for creating or updating a character",
            properties: {
              name: { type: :string, example: "Aragorn" },
              race: { type: :string, example: "Human" },
              realm: { type: :string, example: "Gondor" },
              title: { type: :string, example: "Ranger of the North" },
              ring_bearer: { type: :boolean, example: false },
              level: { type: :integer, example: 20 },
              xp: { type: :integer, example: 5000 },
              strength: { type: :integer, example: 18 },
              wisdom: { type: :integer, example: 14 },
              endurance: { type: :integer, example: 16 },
              status: { type: :string, enum: %w[idle on_quest fallen] }
            },
            required: %w[name race strength wisdom endurance]
          },

          Quest: {
            type: :object,
            description: "A quest in the simulation",
            properties: {
              id: { type: :integer, example: 1 },
              title: { type: :string, example: "Destroy the One Ring" },
              description: {
                type: :string, nullable: true,
                example: "Journey to Mount Doom and cast the Ring into the fires of Orodruin."
              },
              status: { type: :string, enum: %w[pending active completed failed], example: "active" },
              danger_level: { type: :integer, minimum: 1, maximum: 10, example: 10 },
              region: { type: :string, nullable: true, example: "Mordor" },
              progress: { type: :number, format: :float, example: 0.0, description: "Decimal (0–1 scale)" },
              success_chance: {
                type: :number, format: :float, nullable: true, example: 0.45,
                description: "Decimal success probability (0–1 scale), null if uncalculated"
              },
              quest_type: { type: :string, enum: %w[campaign random], example: "campaign" },
              campaign_order: { type: :integer, nullable: true, example: 1 },
              attempts: { type: :integer, example: 0 },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: %w[id title status danger_level]
          },

          QuestDetail: {
            allOf: [
              { "$ref" => "#/components/schemas/Quest" },
              {
                type: :object,
                description: "Quest with nested member list",
                properties: {
                  members: {
                    type: :array,
                    items: { "$ref" => "#/components/schemas/CharacterSummary" }
                  }
                }
              }
            ]
          },

          QuestSummary: {
            type: :object,
            description: "Abbreviated quest info used in nested responses",
            properties: {
              id: { type: :integer, example: 1 },
              title: { type: :string, example: "Destroy the One Ring" },
              status: { type: :string, enum: %w[pending active completed failed], example: "active" },
              danger_level: { type: :integer, example: 10 }
            },
            required: %w[id title status danger_level]
          },

          QuestInput: {
            type: :object,
            description: "Payload for creating or updating a quest",
            properties: {
              title: { type: :string, example: "The Battle of Helm's Deep" },
              description: { type: :string, example: "Defend the fortress against Saruman's army." },
              status: { type: :string, enum: %w[pending active completed failed] },
              danger_level: { type: :integer, minimum: 1, maximum: 10, example: 8 },
              region: { type: :string, example: "Rohan" },
              progress: { type: :number, format: :float, example: 0.0 },
              quest_type: { type: :string, enum: %w[campaign random] },
              campaign_order: { type: :integer, example: 2 },
              attempts: { type: :integer, example: 0 }
            },
            required: %w[title danger_level]
          },

          Artifact: {
            type: :object,
            description: "A magical artifact in the simulation",
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: "The One Ring" },
              artifact_type: { type: :string, example: "ring" },
              # power is stored as text in the database
              power: { type: :string, nullable: true, example: "100", description: "Artifact power level (text column)" },
              corrupted: { type: :boolean, example: true },
              character_id: { type: :integer, nullable: true, example: 1 },
              # stat_bonus is a JSONB column, null: false, defaults to {}
              stat_bonus: {
                type: :object, additionalProperties: true,
                example: { "wisdom" => 5 },
                description: "JSONB bonus stats map; empty object {} when none set"
              },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: %w[id name artifact_type]
          },

          ArtifactDetail: {
            allOf: [
              { "$ref" => "#/components/schemas/Artifact" },
              {
                type: :object,
                description: "Artifact with owning character details",
                properties: {
                  character: {
                    nullable: true,
                    allOf: [{ "$ref" => "#/components/schemas/CharacterSummary" }]
                  }
                }
              }
            ]
          },

          ArtifactSummary: {
            type: :object,
            description: "Abbreviated artifact info used in nested responses",
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: "Sting" },
              artifact_type: { type: :string, example: "sword" },
              power: { type: :string, nullable: true, example: "75" },
              corrupted: { type: :boolean, example: false }
            },
            required: %w[id name artifact_type]
          },

          ArtifactInput: {
            type: :object,
            description: "Payload for creating or updating an artifact",
            properties: {
              name: { type: :string, example: "Mithril Coat" },
              artifact_type: { type: :string, example: "armour" },
              power: { type: :string, example: "90" },
              corrupted: { type: :boolean, example: false },
              character_id: { type: :integer, nullable: true, example: 1 },
              stat_bonus: {
                type: :object,
                additionalProperties: true,
                example: { "endurance" => 20 }
              }
            },
            required: %w[name artifact_type]
          },

          QuestEvent: {
            type: :object,
            description: "An event recorded on a quest (append-only; no updated_at)",
            properties: {
              id: { type: :integer, example: 1 },
              quest_id: { type: :integer, example: 1 },
              event_type: {
                type: :string,
                enum: %w[started progress completed failed restarted artifact_found],
                example: "progress"
              },
              message: {
                type: :string,
                nullable: true,
                example: "The fellowship has crossed the Misty Mountains."
              },
              # data is JSONB null: false, defaults to {}
              data: {
                type: :object, additionalProperties: true,
                description: "JSONB payload; empty object {} when not set"
              },
              created_at: { type: :string, format: "date-time" }
            },
            required: %w[id quest_id event_type]
          },

          QuestEventWithQuest: {
            allOf: [
              { "$ref" => "#/components/schemas/QuestEvent" },
              {
                type: :object,
                description: "Quest event with the parent quest title included",
                properties: {
                  quest_title: { type: :string, example: "Destroy the One Ring" }
                },
                required: %w[quest_title]
              }
            ]
          },

          EventsResponse: {
            type: :object,
            description: "Paginated list of quest events",
            properties: {
              events: {
                type: :array,
                items: { "$ref" => "#/components/schemas/QuestEventWithQuest" }
              },
              meta: {
                type: :object,
                description: "Pagination metadata",
                properties: {
                  total: { type: :integer, example: 150, description: "Total number of matching events" },
                  page: { type: :integer, example: 1, description: "Current page number" },
                  per_page: { type: :integer, example: 25, description: "Results per page" },
                  total_pages: { type: :integer, example: 6, description: "Total number of pages" }
                },
                required: %w[total page per_page total_pages]
              }
            },
            required: %w[events meta]
          },

          SimulationConfig: {
            type: :object,
            description: "Global simulation configuration (singleton)",
            properties: {
              id: { type: :integer, example: 1 },
              mode: { type: :string, enum: %w[campaign random], example: "campaign" },
              running: { type: :boolean, example: false },
              # decimal columns — Rails serializes as strings
              progress_min: {
                type: :string, example: "0.0100",
                description: "Minimum tick progress increment (decimal string)"
              },
              progress_max: {
                type: :string, example: "0.0500",
                description: "Maximum tick progress increment (decimal string)"
              },
              campaign_position: { type: :integer, example: 0 },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: %w[id mode running]
          },

          LeaderboardEntry: {
            type: :object,
            description: "Character summary for leaderboard ranking",
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: "Gandalf the White" },
              race: { type: :string, example: "Wizard" },
              level: { type: :integer, example: 20 },
              xp: { type: :integer, example: 99_999 },
              status: { type: :string, enum: %w[idle on_quest fallen], example: "idle" }
            },
            required: %w[id name level xp status]
          },

          QueuedResponse: {
            type: :object,
            description: "Acknowledgement that a message was enqueued to SQS",
            properties: {
              queued: { type: :boolean, example: true }
            },
            required: %w[queued]
          },

          HealthStatus: {
            type: :object,
            description: "API health check response",
            properties: {
              status: { type: :string, example: "ok" },
              version: { type: :string, example: "0.1.0" },
              environment: { type: :string, example: "production" }
            },
            required: %w[status version environment]
          },

          ErrorResponse: {
            type: :object,
            description: "Single-error response",
            properties: {
              error: { type: :string, example: "Not found" }
            },
            required: %w[error]
          },

          ChaosWoundCharacterResult: {
            type: :object,
            description: "Result of wounding a character via chaos injection",
            properties: {
              affected: {
                type: :object,
                properties: {
                  id: { type: :integer, example: 1 },
                  name: { type: :string, example: "Boromir" },
                  status: { type: :string, example: "fallen" },
                  quest_id: { type: :integer, nullable: true, example: nil }
                },
                required: %w[id name status]
              }
            },
            required: %w[affected]
          },

          ChaosFailQuestResult: {
            type: :object,
            description: "Result of failing a quest via chaos injection",
            properties: {
              affected: {
                type: :object,
                properties: {
                  id: { type: :integer, example: 1 },
                  title: { type: :string, example: "Destroy the One Ring" },
                  status: { type: :string, example: "failed" },
                  progress: { type: :number, format: :float, example: 0.0 },
                  members_reset: { type: :integer, example: 3 }
                },
                required: %w[id title status progress members_reset]
              }
            },
            required: %w[affected]
          },

          ChaosSpikeResult: {
            type: :object,
            description: "Result of spiking threat level via chaos injection",
            properties: {
              affected: {
                type: :object,
                properties: {
                  region: { type: :string, example: "Mordor" },
                  threat_level: { type: :integer, example: 10 },
                  quest_id: { type: :integer, example: 1 }
                },
                required: %w[region threat_level quest_id]
              }
            },
            required: %w[affected]
          },

          ChaosStopSimulationResult: {
            type: :object,
            description: "Result of stopping the simulation via chaos injection",
            properties: {
              affected: {
                type: :object,
                properties: {
                  simulation_running: { type: :boolean, example: false },
                  message: { type: :string, example: "The Eye of Sauron loses focus — simulation halted." }
                },
                required: %w[simulation_running message]
              }
            },
            required: %w[affected]
          },

          ValidationErrors: {
            type: :object,
            description: "Validation failure response with multiple messages",
            properties: {
              errors: {
                type: :array,
                items: { type: :string },
                example: ["Name can't be blank", "Level must be greater than 0"]
              }
            },
            required: %w[errors]
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
