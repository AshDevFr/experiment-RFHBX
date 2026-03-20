# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestEventsChannel, type: :channel do
  describe "#subscribed" do
    context "without a quest_id parameter" do
      it "subscribes to the global quest_events stream" do
        subscribe

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("quest_events")
      end
    end

    context "with a quest_id parameter" do
      it "subscribes to the quest-scoped stream" do
        subscribe(quest_id: 42)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("quest_events:42")
      end

      it "does not subscribe to the global stream" do
        subscribe(quest_id: 42)

        expect(subscription).not_to have_stream_from("quest_events")
      end
    end
  end

  describe "#unsubscribed" do
    it "unsubscribes without error" do
      subscribe
      expect { unsubscribe }.not_to raise_error
    end
  end
end
