# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestEventsChannel, type: :channel do
  let(:principal) { Principal.new("sub" => "user-123", "email" => "frodo@shire.example.com", "roles" => []) }

  describe "#subscribed" do
    context "when authenticated" do
      before { stub_connection current_principal: principal }

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

    context "when unauthenticated (no current_principal)" do
      before { stub_connection current_principal: nil }

      it "rejects the subscription" do
        subscribe

        expect(subscription).to be_rejected
      end
    end
  end

  describe "#unsubscribed" do
    before { stub_connection current_principal: principal }

    it "unsubscribes without error" do
      subscribe
      expect { unsubscribe }.not_to raise_error
    end
  end
end
