# frozen_string_literal: true

# Builds a broadcast payload from a QuestEvent and broadcasts it to
# Action Cable streams.  Each event is sent to:
#   1. The global "quest_events" stream (all subscribers)
#   2. The quest-scoped "quest_events:<quest_id>" stream
#
# Usage:
#   QuestEventBroadcaster.broadcast(quest_event)
#   QuestEventBroadcaster.new(quest_event).broadcast
class QuestEventBroadcaster
  GLOBAL_STREAM = "quest_events"

  attr_reader :quest_event

  def initialize(quest_event)
    @quest_event = quest_event
  end

  def self.broadcast(quest_event)
    new(quest_event).broadcast
  end

  def broadcast
    payload = build_payload

    ActionCable.server.broadcast(GLOBAL_STREAM, payload)
    ActionCable.server.broadcast(quest_stream, payload)
  end

  private

  def quest_stream
    "#{GLOBAL_STREAM}:#{quest_event.quest_id}"
  end

  def build_payload
    quest = quest_event.quest

    {
      event_type: quest_event.event_type,
      quest_id: quest.id,
      quest_name: quest.title,
      region: quest.region,
      message: quest_event.message,
      data: quest_event.data,
      occurred_at: quest_event.created_at&.iso8601
    }
  end
end
