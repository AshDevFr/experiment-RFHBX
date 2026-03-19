# frozen_string_literal: true

require "rails_helper"

RSpec.describe EyeOfSauronWorker, type: :job do
  subject(:worker) { described_class.new }

  describe "#perform" do
    context "when no active quests exist" do
      before { Quest.where(status: :active).destroy_all }

      it "does not create a QuestEvent" do
        expect { worker.perform }.not_to change(QuestEvent, :count)
      end
    end

    context "when active quests exist" do
      let!(:quest) { create(:quest, :active, region: "Mordor", danger_level: 5) }

      it "creates exactly one QuestEvent" do
        expect { worker.perform }.to change(QuestEvent, :count).by(1)
      end

      it "creates a QuestEvent with event_type :progress" do
        worker.perform
        expect(QuestEvent.last.event_type).to eq("progress")
      end

      it "stores region in the event data" do
        allow(worker).to receive(:select_region).and_return("Mordor")
        worker.perform
        expect(QuestEvent.last.data["region"]).to eq("Mordor")
      end

      it "stores threat_level in the event data" do
        allow(worker).to receive(:select_region).and_return("Mordor")
        worker.perform
        expect(QuestEvent.last.data["threat_level"]).to eq(5)
      end

      it "includes a narrative message" do
        worker.perform
        expect(QuestEvent.last.message).to match(/Eye of Sauron|Sauron|lidless Eye|shadow/i)
      end

      it "interpolates the region name into the message" do
        allow(worker).to receive(:select_region).and_return("Mordor")
        worker.perform
        expect(QuestEvent.last.message).to include("Mordor")
      end

      it "anchors the event to an active quest" do
        worker.perform
        expect(QuestEvent.last.quest).to eq(quest)
      end

      it "calls broadcast_sauron_gaze" do
        expect(worker).to receive(:broadcast_sauron_gaze).once
        worker.perform
      end

      it "event appears in the global events feed (QuestEvent.all)" do
        worker.perform
        expect(QuestEvent.all).to include(QuestEvent.last)
      end
    end
  end

  describe "threat level calculation" do
    subject(:threat_level) { worker.send(:calculate_threat_level, active_quests, region) }

    let(:region) { "Mordor" }

    context "with no active quests in the region" do
      let(:active_quests) { [build(:quest, region: "Rohan", danger_level: 5)] }

      it "returns 0" do
        expect(threat_level).to eq(0)
      end
    end

    context "with one active quest in the region" do
      let(:active_quests) { [build(:quest, region: "Mordor", danger_level: 7)] }

      it "returns that quest's danger_level" do
        expect(threat_level).to eq(7)
      end
    end

    context "with multiple active quests in the region" do
      let(:active_quests) do
        [
          build(:quest, region: "Mordor", danger_level: 6),
          build(:quest, region: "Mordor", danger_level: 5),
          build(:quest, region: "Rohan",  danger_level: 9)
        ]
      end

      it "sums danger_levels across quests in the region" do
        expect(threat_level).to eq(11.clamp(0, 10)) # 6+5=11, capped at 10
      end
    end

    context "when sum exceeds 10" do
      let(:active_quests) do
        [
          build(:quest, region: "Mordor", danger_level: 8),
          build(:quest, region: "Mordor", danger_level: 7)
        ]
      end

      it "caps threat_level at 10" do
        expect(threat_level).to eq(10)
      end
    end

    context "with exactly 10 danger" do
      let(:active_quests) { [build(:quest, region: "Mordor", danger_level: 10)] }

      it "returns 10" do
        expect(threat_level).to eq(10)
      end
    end
  end

  describe "region selection weighting" do
    subject(:select_region) { worker.send(:select_region, active_quests) }

    context "with quests in only one region" do
      let(:active_quests) do
        [
          build(:quest, region: "Mordor", danger_level: 8),
          build(:quest, region: "Mordor", danger_level: 5)
        ]
      end

      it "always selects the region that has active quests" do
        # With all weight concentrated in Mordor, rand output doesn't matter
        results = 10.times.map { worker.send(:select_region, active_quests) }
        expect(results).to all(eq("Mordor"))
      end
    end

    context "with high-danger quests dominating one region" do
      let(:active_quests) do
        [
          build(:quest, region: "Mordor",    danger_level: 10),
          build(:quest, region: "The Shire", danger_level: 1)
        ]
      end

      it "selects the high-danger region when rand falls within its weight" do
        # Mordor weight = 10, The Shire weight = 1, total = 11
        # rand returning 0.0 → threshold=0.0, first region with cumulative > 0 wins
        allow(worker).to receive(:rand).and_return(0.0)
        expect(select_region).to eq("Mordor")
      end

      it "selects the low-danger region only when rand falls at the tail end" do
        # Mordor weight=10, The Shire weight=1 — The Shire is last in weights
        # rand returning just below 1.0 selects The Shire
        allow(worker).to receive(:rand).and_return(0.999)
        expect(select_region).to eq("The Shire")
      end
    end

    context "when active quests are outside the known region pool" do
      let(:active_quests) { [build(:quest, region: "Gondor", danger_level: 9)] }

      it "returns a region from the REGIONS pool" do
        result = select_region
        expect(EyeOfSauronWorker::REGIONS).to include(result)
      end
    end
  end

  describe "anchor_quest selection" do
    subject(:anchor) { worker.send(:anchor_quest, active_quests, region) }

    let(:region) { "Mordor" }

    context "when quests exist in the selected region" do
      let!(:low)  { build(:quest, region: "Mordor", danger_level: 3) }
      let!(:high) { build(:quest, region: "Mordor", danger_level: 9) }
      let(:active_quests) { [low, high] }

      it "returns the highest-danger quest in the region" do
        expect(anchor).to eq(high)
      end
    end

    context "when no quests are in the selected region" do
      let!(:elsewhere) { build(:quest, region: "Rohan", danger_level: 7) }
      let(:active_quests) { [elsewhere] }

      it "falls back to the highest-danger active quest overall" do
        expect(anchor).to eq(elsewhere)
      end
    end
  end

  describe "REGIONS constant" do
    it "includes all expected Middle-earth regions" do
      expected = %w[Mordor Moria Rohan Rivendell Isengard Wilderness].map(&:downcase)
      actual = described_class::REGIONS.map(&:downcase)
      expect(actual).to include(*expected)
    end

    it "contains 9 regions" do
      expect(described_class::REGIONS.length).to eq(9)
    end
  end

  describe "Sidekiq options" do
    it "uses the default queue" do
      expect(described_class.sidekiq_options["queue"].to_s).to eq("default")
    end
  end
end
