# frozen_string_literal: true

# Streams quest lifecycle events to connected clients.
#
# Subscribe to all quest events:
#   { "command": "subscribe", "identifier": "{\"channel\":\"QuestEventsChannel\"}" }
#
# Subscribe to a specific quest's events:
#   { "command": "subscribe", "identifier": "{\"channel\":\"QuestEventsChannel\",\"quest_id\":42}" }
#
# Broadcasts are performed by QuestEventBroadcaster — this channel only
# manages stream subscriptions.
class QuestEventsChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_principal.present?

    if quest_id.present?
      stream_from "quest_events:#{quest_id}"
    else
      stream_from "quest_events"
    end
  end

  def unsubscribed
    # No cleanup needed — Action Cable handles stream teardown automatically.
  end

  private

  def quest_id
    params["quest_id"]
  end
end
