# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestEventBroadcaster do
  let(:quest) do
    create(:quest, :active, title: "Destroy the Ring", region: "Mordor")
  end

  let(:quest_event) do
    create(:quest_event, :progress,
      quest: quest,
      message: "The fellowship advances.",
      data: { "progress" => 0.5, "increment" => 0.05 })
  end

  describe ".broadcast" do
    it "broadcasts to the global quest_events stream" do
      expect(ActionCable.server).to receive(:broadcast)
        .with("quest_events", hash_including(event_type: "progress"))
      expect(ActionCable.server).to receive(:broadcast)
        .with("quest_events:#{quest.id}", anything)

      described_class.broadcast(quest_event)
    end

    it "broadcasts to the quest-scoped stream" do
      expect(ActionCable.server).to receive(:broadcast)
        .with("quest_events", anything)
      expect(ActionCable.server).to receive(:broadcast)
        .with("quest_events:#{quest.id}", hash_including(quest_id: quest.id))

      described_class.broadcast(quest_event)
    end
  end

  describe "payload shape" do
    let(:payload) { nil }

    before do
      allow(ActionCable.server).to receive(:broadcast) do |_stream, data|
        # capture last broadcast payload
        @captured_payload = data
      end

      described_class.broadcast(quest_event)
    end

    it "includes event_type" do
      expect(@captured_payload[:event_type]).to eq("progress")
    end

    it "includes quest_id" do
      expect(@captured_payload[:quest_id]).to eq(quest.id)
    end

    it "includes quest_name" do
      expect(@captured_payload[:quest_name]).to eq("Destroy the Ring")
    end

    it "includes region" do
      expect(@captured_payload[:region]).to eq("Mordor")
    end

    it "includes message" do
      expect(@captured_payload[:message]).to eq("The fellowship advances.")
    end

    it "includes data hash" do
      expect(@captured_payload[:data]).to eq({ "progress" => 0.5, "increment" => 0.05 })
    end

    it "includes occurred_at as ISO 8601" do
      expect(@captured_payload[:occurred_at]).to match(/\A\d{4}-\d{2}-\d{2}T/)
    end
  end

  describe "all event types broadcast correctly" do
    %i[started progress completed failed restarted].each do |event_type_trait|
      it "broadcasts #{event_type_trait} events" do
        event = create(:quest_event, event_type_trait, quest: quest)

        expect(ActionCable.server).to receive(:broadcast)
          .with("quest_events", hash_including(event_type: event_type_trait.to_s))
        expect(ActionCable.server).to receive(:broadcast)
          .with("quest_events:#{quest.id}", hash_including(event_type: event_type_trait.to_s))

        described_class.broadcast(event)
      end
    end
  end

  describe "broadcast to empty channel" do
    it "does not raise when no subscribers are listening" do
      expect { described_class.broadcast(quest_event) }.not_to raise_error
    end
  end
end
