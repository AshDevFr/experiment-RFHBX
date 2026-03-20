# frozen_string_literal: true

class SauronGazeChannel < ApplicationCable::Channel
  def subscribed
    stream_from "sauron_gaze"
  end

  def unsubscribed
    # No cleanup needed — clients simply stop receiving broadcasts.
  end
end
