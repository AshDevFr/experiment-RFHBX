# frozen_string_literal: true

require "rails_helper"

RSpec.describe SauronGazeChannel, type: :channel do
  describe "#subscribed" do
    it "successfully subscribes to the sauron_gaze stream" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("sauron_gaze")
    end
  end

  describe "#unsubscribed" do
    it "disconnects cleanly" do
      subscribe
      expect { subscription.unsubscribe_from_channel }.not_to raise_error
    end
  end
end
