# frozen_string_literal: true

require "rails_helper"

RSpec.describe SauronGazeChannel, type: :channel do
  let(:principal) { Principal.new("sub" => "user-123", "email" => "frodo@shire.example.com", "roles" => []) }

  describe "#subscribed" do
    context "when authenticated" do
      before { stub_connection current_principal: principal }

      it "successfully subscribes to the sauron_gaze stream" do
        subscribe

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("sauron_gaze")
      end
    end

    context "when unauthenticated (no current_principal)" do
      before { stub_connection current_principal: nil }

      it "rejects the subscription" do
        subscribe

        expect(subscription).to be_rejected
      end

      it "does not stream from sauron_gaze" do
        subscribe

        expect(subscription).to be_rejected
        expect(subscription.streams).to be_empty
      end
    end
  end

  describe "#unsubscribed" do
    before { stub_connection current_principal: principal }

    it "disconnects cleanly" do
      subscribe
      expect { subscription.unsubscribe_from_channel }.not_to raise_error
    end
  end
end
