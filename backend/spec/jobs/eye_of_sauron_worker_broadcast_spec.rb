# frozen_string_literal: true

require "rails_helper"

RSpec.describe EyeOfSauronWorker, "broadcast_sauron_gaze", type: :job do
  subject(:worker) { described_class.new }

  let!(:quest) { create(:quest, :active, region: "Mordor", danger_level: 5) }

  describe "#broadcast_sauron_gaze" do
    it "broadcasts to the sauron_gaze stream" do
      expect {
        worker.perform
      }.to have_broadcasted_to("sauron_gaze")
    end

    it "includes region in the broadcast payload" do
      allow(worker).to receive(:select_region).and_return("Mordor")

      expect {
        worker.perform
      }.to have_broadcasted_to("sauron_gaze").with(
        a_hash_including(region: "Mordor")
      )
    end

    it "includes threat_level in the broadcast payload" do
      allow(worker).to receive(:select_region).and_return("Mordor")

      expect {
        worker.perform
      }.to have_broadcasted_to("sauron_gaze").with(
        a_hash_including(threat_level: 5)
      )
    end

    it "includes a message in the broadcast payload" do
      expect {
        worker.perform
      }.to have_broadcasted_to("sauron_gaze").with(
        a_hash_including(message: a_string_matching(/Eye of Sauron|Sauron|lidless Eye|shadow/i))
      )
    end

    it "includes watched_at as an ISO8601 timestamp" do
      expect {
        worker.perform
      }.to have_broadcasted_to("sauron_gaze").with(
        a_hash_including(watched_at: a_string_matching(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/))
      )
    end

    it "does not broadcast when no active quests exist" do
      Quest.where(status: :active).destroy_all

      expect {
        worker.perform
      }.not_to have_broadcasted_to("sauron_gaze")
    end

    it "broadcasts exactly once per perform call" do
      expect {
        worker.perform
      }.to have_broadcasted_to("sauron_gaze").exactly(:once)
    end
  end
end
