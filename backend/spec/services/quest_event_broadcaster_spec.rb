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

  describe "status-transition payload includes members, status, and attempts" do
    let(:character) { create(:character, name: "Frodo", race: "Hobbit", level: 5, status: :on_quest) }

    before do
      create(:quest_membership, quest: quest, character: character)
      allow(ActionCable.server).to receive(:broadcast) do |_stream, data|
        @captured_payload = data
      end
    end

    %i[started completed failed restarted].each do |event_type_trait|
      context "for #{event_type_trait} events" do
        let(:status_event) { create(:quest_event, event_type_trait, quest: quest) }

        before { described_class.broadcast(status_event) }

        it "includes members array with character data" do
          expect(@captured_payload[:members]).to be_an(Array)
          member = @captured_payload[:members].first
          expect(member["id"]).to eq(character.id)
          expect(member["name"]).to eq("Frodo")
          expect(member["race"]).to eq("Hobbit")
          expect(member["level"]).to eq(5)
        end

        it "includes quest status" do
          expect(@captured_payload[:status]).to eq(quest.status)
        end

        it "includes quest attempts" do
          expect(@captured_payload[:attempts]).to eq(quest.attempts)
        end
      end
    end

    context "for progress events" do
      before { described_class.broadcast(quest_event) }

      it "does not include members" do
        expect(@captured_payload).not_to have_key(:members)
      end

      it "does not include status" do
        expect(@captured_payload).not_to have_key(:status)
      end

      it "does not include attempts" do
        expect(@captured_payload).not_to have_key(:attempts)
      end
    end
  end

  describe "broadcast to empty channel" do
    it "does not raise when no subscribers are listening" do
      expect { described_class.broadcast(quest_event) }.not_to raise_error
    end
  end
end
