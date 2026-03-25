# frozen_string_literal: true

module Api
  module V1
    class ChaosController < ApplicationController
      # POST /api/v1/chaos/wound_character
      # Targets a random on_quest character: sets them to fallen, removes from
      # active quest membership, and creates a failed QuestEvent noting the casualty.
      def wound_character
        character = Character.where(status: :on_quest).order(Arel.sql("RANDOM()")).first

        unless character
          return render json: { error: "No characters currently on a quest to wound" },
                        status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          membership = QuestMembership.joins(:quest)
                                      .where(character: character, quests: { status: :active })
                                      .first
          quest = membership&.quest

          character.update!(status: :fallen)
          membership&.destroy!

          if quest
            event = QuestEvent.create!(
              quest: quest,
              event_type: :failed,
              message: "#{character.name} has fallen in #{quest.region || 'the wilderness'} — a grievous casualty.",
              data: {
                "chaos_action" => "wound_character",
                "character_id" => character.id,
                "character_name" => character.name
              }
            )
            QuestEventBroadcaster.broadcast(event)
          end
        end

        render json: {
          affected: {
            id: character.id,
            name: character.name,
            status: character.status,
            quest_id: QuestMembership.joins(:quest)
                        .where(character: character, quests: { status: :active })
                        .pick(:quest_id)
          }
        }
      end

      # POST /api/v1/chaos/fail_quest
      # Immediately fails a random active quest: resets progress to 0, sets
      # member characters back to idle, and creates a failed QuestEvent.
      def fail_quest
        quest = Quest.where(status: :active).order(Arel.sql("RANDOM()")).first

        unless quest
          return render json: { error: "No active quests to fail" },
                        status: :unprocessable_entity
        end

        members_affected = []

        ActiveRecord::Base.transaction do
          quest.update!(status: :failed, progress: 0.0)

          quest.characters.where(status: :on_quest).find_each do |character|
            character.update!(status: :idle)
            members_affected << { id: character.id, name: character.name }
          end

          event = QuestEvent.create!(
            quest: quest,
            event_type: :failed,
            message: "Chaos strikes! \"#{quest.title}\" has been sabotaged — all progress lost.",
            data: {
              "chaos_action" => "fail_quest",
              "quest_id" => quest.id,
              "members_reset" => members_affected.size
            }
          )
          QuestEventBroadcaster.broadcast(event)
        end

        render json: {
          affected: {
            id: quest.id,
            title: quest.title,
            status: quest.status,
            progress: quest.progress.to_f,
            members_reset: members_affected.size
          }
        }
      end

      # POST /api/v1/chaos/spike_threat
      # Publishes a threat-level spike (level 10) via the sauron_gaze channel.
      # The next EyeOfSauronWorker tick will recalculate the real threat level,
      # so the spike is temporary by design.
      def spike_threat
        active_quest = Quest.where(status: :active).order(Arel.sql("RANDOM()")).first

        unless active_quest
          return render json: { error: "No active quests — cannot spike threat level" },
                        status: :unprocessable_entity
        end

        region = active_quest.region || EyeOfSauronWorker::REGIONS.sample

        event = QuestEvent.create!(
          quest: active_quest,
          event_type: :progress,
          message: "The Eye of Sauron blazes with sudden fury over #{region}! Threat level surges to maximum!",
          data: {
            "chaos_action" => "spike_threat",
            "region" => region,
            "threat_level" => 10
          }
        )
        QuestEventBroadcaster.broadcast(event)

        ActionCable.server.broadcast("sauron_gaze", {
          region: region,
          threat_level: 10,
          message: "The Eye of Sauron blazes with sudden fury over #{region}! Threat level surges to maximum!",
          watched_at: Time.current.iso8601
        })

        render json: {
          affected: {
            region: region,
            threat_level: 10,
            quest_id: active_quest.id
          }
        }
      end

      # POST /api/v1/chaos/stop_simulation
      # Stops the simulation and broadcasts a special Sauron event.
      def stop_simulation
        config = SimulationConfig.current

        unless config.running?
          return render json: { error: "Simulation is not running" },
                        status: :unprocessable_entity
        end

        config.update!(running: false)

        ActionCable.server.broadcast("sauron_gaze", {
          region: "All Regions",
          threat_level: 0,
          message: "The Eye of Sauron loses focus \u2014 simulation halted.",
          watched_at: Time.current.iso8601
        })

        render json: {
          affected: {
            simulation_running: config.running?,
            message: "The Eye of Sauron loses focus \u2014 simulation halted."
          }
        }
      end
    end
  end
end
