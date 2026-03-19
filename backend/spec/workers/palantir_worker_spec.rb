# frozen_string_literal: true

require "rails_helper"

RSpec.describe PalantirWorker, type: :worker do
  subject(:worker) { described_class.new }

  let!(:quest) { create(:quest, status: :active) }

  describe "#perform" do
    let(:sqs_msg) { double("SQS::Message") }

    context "when an active quest exists" do
      it "creates a QuestEvent with event_type :progress" do
        expect {
          worker.perform(sqs_msg, { "message" => "Fly, you fools!" }.to_json)
        }.to change(QuestEvent, :count).by(1)

        event = QuestEvent.last
        expect(event.event_type).to eq("progress")
        expect(event.quest).to eq(quest)
        expect(event.data["message"]).to eq("Fly, you fools!")
      end

      it "stores message content in data field" do
        worker.perform(sqs_msg, { "message" => "The Eye of Sauron watches" }.to_json)

        event = QuestEvent.last
        expect(event.data).to include("message" => "The Eye of Sauron watches")
      end

      it "targets the most recent active quest" do
        older_quest = create(:quest, status: :active, created_at: 1.hour.ago)
        worker.perform(sqs_msg, { "message" => "test" }.to_json)

        event = QuestEvent.last
        expect(event.quest).to eq(quest)
        expect(event.quest).not_to eq(older_quest)
      end
    end

    context "when no active quest exists" do
      before { quest.update!(status: :completed) }

      it "does not create a QuestEvent" do
        expect {
          worker.perform(sqs_msg, { "message" => "No quest to receive this" }.to_json)
        }.not_to change(QuestEvent, :count)
      end
    end

    context "when body is a plain string (non-JSON)" do
      it "creates a QuestEvent and stores the string as message" do
        expect {
          worker.perform(sqs_msg, "Plain text message")
        }.to change(QuestEvent, :count).by(1)

        event = QuestEvent.last
        expect(event.event_type).to eq("progress")
        expect(event.data["message"]).to eq("Plain text message")
      end
    end
  end

  describe "Shoryuken options" do
    it "is configured for the palantir-queue" do
      queue = described_class.get_shoryuken_options["queue"]
      expect(queue).to eq(ENV.fetch("SQS_QUEUE_NAME", "palantir-queue"))
    end

    it "auto-deletes messages after processing" do
      expect(described_class.get_shoryuken_options["auto_delete"]).to be(true)
    end
  end
end
