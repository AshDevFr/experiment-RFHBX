# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestTickWorker, type: :job do
  let(:config) { SimulationConfig.current }

  before do
    SimulationConfig.destroy_all
    config.update!(running: true)
  end

  describe "#perform" do
    it "does nothing when simulation is not running" do
      config.update!(running: false)
      expect { subject.perform }.not_to change(QuestEvent, :count)
    end

    it "increments tick_count when running" do
      expect { subject.perform }.to change { config.reload.tick_count }.by(1)
    end

    context "with active quests" do
      let!(:quest) { create(:quest, :active, danger_level: 5, progress: 0.0) }
      let!(:character) { create(:character, status: :on_quest, strength: 10, wisdom: 10, endurance: 10, level: 1) }

      before do
        create(:quest_membership, quest: quest, character: character)
      end

      it "increments progress on active quests" do
        expect { subject.perform }.to change { quest.reload.progress.to_f }
      end

      it "creates a progress QuestEvent per active quest" do
        expect { subject.perform }.to change(QuestEvent, :count).by_at_least(1)
        event = QuestEvent.last
        expect(event.event_type).to eq("progress")
        expect(event.quest).to eq(quest)
      end

      it "includes progress data in the event" do
        subject.perform
        event = QuestEvent.where(quest: quest, event_type: :progress).last
        expect(event.data).to include("progress", "increment")
      end

      it "progress stays within configured min/max range" do
        # Use a very tight range to test bounds
        config.update!(progress_min: 0.05, progress_max: 0.05)
        subject.perform
        expect(quest.reload.progress.to_f).to be_within(0.001).of(0.05)
      end

      it "clamps progress to 1.0 and does not exceed it" do
        quest.update!(progress: 0.98)
        config.update!(progress_min: 0.05, progress_max: 0.05)
        subject.perform
        expect(quest.reload.progress.to_f).to be <= 1.0
      end

      it "does not broadcast a progress event when progress reaches 1.0" do
        quest.update!(progress: 0.98)
        config.update!(progress_min: 0.05, progress_max: 0.05)
        # Force success so quest completes
        allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(1.0)
        allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)

        broadcasts = []
        allow(QuestEventBroadcaster).to receive(:broadcast) { |e| broadcasts << e }

        subject.perform

        progress_broadcasts = broadcasts.select { |e| e.event_type == "progress" }
        expect(progress_broadcasts).to be_empty
      end
    end

    context "quest completion — success" do
      let!(:quest) { create(:quest, :active, danger_level: 1, progress: 0.99) }
      let!(:character) do
        create(:character, status: :on_quest, strength: 20, wisdom: 20, endurance: 20, level: 1, xp: 0)
      end

      before do
        create(:quest_membership, quest: quest, character: character)
        # High progress_min so quest completes this tick
        config.update!(progress_min: 0.05, progress_max: 0.1)
        # Seed random for deterministic success (party_power = 60 * 1.1 = 66, success_chance = 66/100*50 = 33 clamped)
        # With danger_level 1: success_chance = (66/100)*50 = 33 — use a seed that rolls under
        allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(1.0)
        allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)
      end

      it "marks quest as completed on success" do
        subject.perform
        expect(quest.reload.status).to eq("completed")
      end

      it "awards danger_level * 100 XP to party members" do
        subject.perform
        expect(character.reload.xp).to eq(100) # danger_level 1 * 100
      end

      it "sets characters to idle after success" do
        subject.perform
        expect(character.reload.status).to eq("idle")
      end

      it "creates a completed QuestEvent" do
        subject.perform
        event = QuestEvent.find_by(quest: quest, event_type: :completed)
        expect(event).to be_present
        expect(event.data["result"]).to eq("success")
      end
    end

    context "quest completion — failure" do
      let!(:quest) { create(:quest, :active, danger_level: 10, progress: 0.99, attempts: 0) }
      let!(:character) do
        create(:character, status: :on_quest, strength: 5, wisdom: 5, endurance: 5, level: 1, xp: 0)
      end

      before do
        create(:quest_membership, quest: quest, character: character)
        config.update!(progress_min: 0.05, progress_max: 0.1)
        # Force failure: party_power = 15 * 1.1 = 16.5, success_chance = (16.5/1000)*50 = 0.825 → clamped to 5
        allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(50.0)
        allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)
      end

      it "awards danger_level * 25 XP on failure" do
        subject.perform
        expect(character.reload.xp).to eq(250) # danger_level 10 * 25
      end

      it "increments attempts on failure" do
        subject.perform
        expect(quest.reload.attempts).to eq(1)
      end

      it "resets progress and re-activates the quest" do
        subject.perform
        quest.reload
        expect(quest.status).to eq("active")
        expect(quest.progress.to_f).to eq(0.0)
      end

      it "creates failed and restarted QuestEvents" do
        subject.perform
        expect(QuestEvent.where(quest: quest, event_type: :failed).count).to eq(1)
        expect(QuestEvent.where(quest: quest, event_type: :restarted).count).to eq(1)
      end

      it "keeps the same party on restart" do
        subject.perform
        expect(quest.reload.characters).to include(character)
        expect(character.reload.status).to eq("on_quest")
      end

      it "broadcasts the failed event (not just restarted)" do
        broadcasts = []
        allow(QuestEventBroadcaster).to receive(:broadcast) { |e| broadcasts << e }

        subject.perform

        broadcast_types = broadcasts.map(&:event_type)
        expect(broadcast_types).to include("failed")
        expect(broadcast_types).to include("restarted")
      end
    end
  end

  describe "success_chance formula" do
    subject(:worker) { described_class.new }

    it "returns minimum 5 when party is very weak" do
      result = worker.send(:calculate_success_chance, 1.0, 10)
      expect(result).to eq(5.0)
    end

    it "returns maximum 95 when party is very strong" do
      result = worker.send(:calculate_success_chance, 10_000.0, 1)
      expect(result).to eq(95.0)
    end

    it "calculates correctly for balanced values" do
      # party_power=200, danger_level=1 → (200/100)*50 = 100 → clamped to 95
      result = worker.send(:calculate_success_chance, 200.0, 1)
      expect(result).to eq(95.0)
    end

    it "calculates mid-range correctly" do
      # party_power=100, danger_level=1 → (100/100)*50 = 50
      result = worker.send(:calculate_success_chance, 100.0, 1)
      expect(result).to eq(50.0)
    end

    it "accounts for danger_level scaling" do
      # party_power=100, danger_level=5 → (100/500)*50 = 10
      result = worker.send(:calculate_success_chance, 100.0, 5)
      expect(result).to eq(10.0)
    end
  end

  describe "party_power calculation" do
    subject(:worker) { described_class.new }

    let!(:quest) { create(:quest, :active) }
    let!(:character) do
      create(:character, status: :on_quest, strength: 10, wisdom: 10, endurance: 10, level: 1)
    end

    before do
      create(:quest_membership, quest: quest, character: character)
    end

    it "sums base stats with level multiplier" do
      # (10+10+10) * (1 + 0.1*1) = 30 * 1.1 = 33
      result = worker.send(:calculate_party_power, quest)
      expect(result).to be_within(0.01).of(33.0)
    end

    it "includes artifact bonuses" do
      create(:artifact, character: character, stat_bonus: { "strength" => 5, "wisdom" => 3 })
      # (10+10+10+5+3) * (1 + 0.1*1) = 38 * 1.1 = 41.8
      result = worker.send(:calculate_party_power, quest)
      expect(result).to be_within(0.01).of(41.8)
    end

    it "scales with level" do
      character.update!(level: 5)
      # (10+10+10) * (1 + 0.1*5) = 30 * 1.5 = 45
      result = worker.send(:calculate_party_power, quest)
      expect(result).to be_within(0.01).of(45.0)
    end

    it "sums across multiple party members" do
      char2 = create(:character, status: :on_quest, strength: 5, wisdom: 5, endurance: 5, level: 1)
      create(:quest_membership, quest: quest, character: char2)
      # char1: 30 * 1.1 = 33, char2: 15 * 1.1 = 16.5, total = 49.5
      result = worker.send(:calculate_party_power, quest)
      expect(result).to be_within(0.01).of(49.5)
    end
  end

  describe "XP and level-up" do
    subject(:worker) { described_class.new }

    it "levels up when XP threshold is crossed" do
      character = create(:character, level: 1, xp: 900)
      character.xp += 200  # total 1100, threshold for level 2 = 1000
      worker.send(:check_level_up, character)
      expect(character.level).to eq(2)
    end

    it "does not level up when XP is below threshold" do
      character = create(:character, level: 1, xp: 400)
      character.xp += 100  # total 500, threshold for level 2 = 1000
      worker.send(:check_level_up, character)
      expect(character.level).to eq(1)
    end

    it "handles multiple level-ups in a single check" do
      character = create(:character, level: 1, xp: 0)
      character.xp = 2500  # threshold L2=1000, L3=1500, L4=2000 → should be level 4
      worker.send(:check_level_up, character)
      expect(character.level).to eq(5) # L2=1000, L3=1500, L4=2000, L5=2500 all crossed
      # Actually: L2=1000✓, L3=1500✓, L4=2000✓, L5=2500✓, L6=3000✗ → level 5
    end

    it "increments a random stat on level-up" do
      character = create(:character, level: 1, xp: 0, strength: 10, wisdom: 10, endurance: 10)
      character.xp = 1000  # exactly L2 threshold
      original_total = character.strength + character.wisdom + character.endurance

      worker.send(:check_level_up, character)
      new_total = character.strength + character.wisdom + character.endurance
      expect(new_total).to eq(original_total + 1)
    end

    context "with quest argument" do
      let!(:quest) { create(:quest, :active, danger_level: 3) }

      it "creates a level_up QuestEvent when quest is provided and level-up occurs" do
        character = create(:character, level: 1, xp: 900)
        character.xp += 200  # crosses L2 threshold (1000)

        expect {
          worker.send(:check_level_up, character, quest)
        }.to change(QuestEvent, :count).by(1)

        event = QuestEvent.find_by(quest: quest, event_type: :level_up)
        expect(event).to be_present
        expect(event.message).to match(/reached level 2/)
        expect(event.data["character_name"]).to eq(character.name)
        expect(event.data["new_level"]).to eq(2)
        expect(event.data["character_id"]).to eq(character.id)
        expect(%w[strength wisdom endurance]).to include(event.data["stat_increased"])
      end

      it "creates one level_up event per level gained" do
        character = create(:character, level: 1, xp: 0)
        character.xp = 2500  # crosses L2 (1000), L3 (1500), L4 (2000), L5 (2500)

        expect {
          worker.send(:check_level_up, character, quest)
        }.to change(QuestEvent, :count).by(4)

        expect(QuestEvent.where(quest: quest, event_type: :level_up).count).to eq(4)
      end

      it "does not create a level_up event when no level-up occurs" do
        character = create(:character, level: 1, xp: 400)
        character.xp += 100  # still below L2 threshold (1000)

        expect {
          worker.send(:check_level_up, character, quest)
        }.not_to change(QuestEvent, :count)
      end

      it "does not create a level_up event when quest is nil" do
        character = create(:character, level: 1, xp: 900)
        character.xp += 200  # crosses threshold

        expect {
          worker.send(:check_level_up, character, nil)
        }.not_to change(QuestEvent, :count)
      end

      it "collects level_up events in @pending_level_up_events for post-commit broadcast" do
        character = create(:character, level: 1, xp: 900)
        character.xp += 200
        worker.instance_variable_set(:@pending_level_up_events, [])

        worker.send(:check_level_up, character, quest)

        pending = worker.instance_variable_get(:@pending_level_up_events)
        expect(pending.length).to eq(1)
        expect(pending.first.event_type).to eq("level_up")
      end
    end
  end

  describe "level_up events during quest success" do
    subject(:worker) { described_class.new }

    let!(:quest) { create(:quest, :active, danger_level: 5, progress: 0.99) }
    # Character needs enough XP after the award to level up:
    # danger_level 5 * 100 = 500 XP awarded; L2 threshold = 1000
    # Start with xp: 600 so that 600 + 500 = 1100 >= 1000 (L2)
    let!(:character) do
      create(:character, status: :on_quest, strength: 20, wisdom: 20, endurance: 20, level: 1, xp: 600)
    end

    before do
      create(:quest_membership, quest: quest, character: character)
      config.update!(progress_min: 0.05, progress_max: 0.1)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(1.0)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)
    end

    it "creates a level_up QuestEvent when a character levels up on quest success" do
      subject.perform
      event = QuestEvent.find_by(quest: quest, event_type: :level_up)
      expect(event).to be_present
      expect(event.message).to match(/reached level 2/)
      expect(event.data["character_id"]).to eq(character.id)
      expect(event.data["new_level"]).to eq(2)
    end

    it "broadcasts level_up events after the transaction commits" do
      broadcasts = []
      allow(QuestEventBroadcaster).to receive(:broadcast) { |e| broadcasts << e }

      subject.perform

      level_up_broadcasts = broadcasts.select { |e| e.event_type == "level_up" }
      expect(level_up_broadcasts).not_to be_empty
    end
  end

  describe "level_up events during quest failure" do
    subject(:worker) { described_class.new }

    let!(:quest) { create(:quest, :active, danger_level: 10, progress: 0.99, attempts: 0) }
    # danger_level 10 * 25 = 250 XP on failure; start at xp: 800 so 800 + 250 = 1050 >= 1000 (L2)
    let!(:character) do
      create(:character, status: :on_quest, strength: 5, wisdom: 5, endurance: 5, level: 1, xp: 800)
    end

    before do
      create(:quest_membership, quest: quest, character: character)
      config.update!(progress_min: 0.05, progress_max: 0.1)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(99.0)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)
    end

    it "creates a level_up QuestEvent when a character levels up on quest failure" do
      subject.perform
      event = QuestEvent.find_by(quest: quest, event_type: :level_up)
      expect(event).to be_present
      expect(event.data["new_level"]).to eq(2)
    end
  end

  describe "campaign mode" do
    let!(:quest1) do
      create(:quest, quest_type: :campaign, campaign_order: 1, status: :pending,
             danger_level: 3, progress: 0.0)
    end
    let!(:quest2) do
      create(:quest, quest_type: :campaign, campaign_order: 2, status: :pending,
             danger_level: 5, progress: 0.0)
    end

    before do
      config.update!(mode: :campaign)
    end

    it "activates the next campaign quest when none are active" do
      create_list(:character, 2, status: :idle)
      subject.perform
      expect(quest1.reload.status).to eq("active")
    end

    it "creates party memberships for campaign quest" do
      create_list(:character, 4, status: :idle)
      subject.perform
      expect(quest1.reload.quest_memberships.count).to be >= 1
    end

    it "updates campaign_position to current quest's campaign_order" do
      create_list(:character, 4, status: :idle)
      subject.perform
      expect(config.reload.campaign_position).to eq(1)
    end

    it "switches to random mode when all campaign quests are completed" do
      quest1.update!(status: :completed)
      quest2.update!(status: :completed)
      subject.perform
      expect(config.reload.mode).to eq("random")
    end
  end

  describe "random mode" do
    before do
      config.update!(mode: :random)
      Quest.where(quest_type: :campaign).destroy_all
    end

    it "generates a random quest when none are active" do
      create_list(:character, 3, status: :idle)
      expect { subject.perform }.to change { Quest.where(quest_type: :random).count }.by(1)
    end

    it "assigns idle characters to the random quest" do
      create_list(:character, 4, status: :idle)
      subject.perform
      random_quest = Quest.where(quest_type: :random, status: :active).last
      expect(random_quest.characters.count).to be_between(2, 4)
    end

    it "does not generate a quest when fewer than 2 idle characters" do
      create(:character, status: :on_quest)
      expect { subject.perform }.not_to change { Quest.where(quest_type: :random).count }
    end

    it "does not generate a quest when a random quest is already active" do
      create_list(:character, 3, status: :idle)
      create(:quest, quest_type: :random, status: :active)
      expect { subject.perform }.not_to change { Quest.where(quest_type: :random).count }
    end

    it "creates a started QuestEvent for the new random quest" do
      create_list(:character, 3, status: :idle)
      subject.perform
      random_quest = Quest.where(quest_type: :random).last
      event = QuestEvent.find_by(quest: random_quest, event_type: :started)
      expect(event).to be_present
    end
  end

  describe "memberless quest guard" do
    let!(:memberless_quest) { create(:quest, :active, danger_level: 5, progress: 0.0) }

    it "skips active quests that have no members" do
      expect { subject.perform }.not_to change { memberless_quest.reload.progress.to_f }
    end

    it "logs a warning for each memberless quest" do
      expect(Rails.logger).to receive(:warn).with(
        /\[QuestTickWorker\] Skipping memberless quest ##{memberless_quest.id}/
      )
      subject.perform
    end

    it "does not create a progress event for memberless quests" do
      expect { subject.perform }.not_to change(QuestEvent, :count)
    end
  end

  describe "broadcast stub" do
    it "responds to broadcast_quest_update without error" do
      worker = described_class.new
      quest = create(:quest)
      expect { worker.send(:broadcast_quest_update, quest, :completed) }.not_to raise_error
    end
  end

  describe "quest success triggers QuestAutoStartWorker" do
    let!(:quest) { create(:quest, :active, danger_level: 1, progress: 0.99) }
    let!(:character) do
      create(:character, status: :on_quest, strength: 20, wisdom: 20, endurance: 20, level: 1, xp: 0)
    end

    before do
      create(:quest_membership, quest: quest, character: character)
      config.update!(progress_min: 0.05, progress_max: 0.1)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(1.0)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)
    end

    it "enqueues QuestAutoStartWorker after a successful quest completion" do
      expect { subject.perform }.to change(QuestAutoStartWorker.jobs, :size).by(1)
    end
  end

  describe "campaign → random mode transition within the same tick" do
    before do
      config.update!(mode: :campaign)
      # All campaign quests are already completed — advance_campaign will switch
      # to random mode; ensure_random_quest should then run immediately.
      create(:quest, quest_type: :campaign, campaign_order: 1, status: :completed)
      create_list(:character, 3, status: :idle)
    end

    it "switches to random mode when all campaign quests are completed" do
      subject.perform
      expect(config.reload.mode).to eq("random")
    end

    it "starts a random quest in the same tick rather than waiting for the next cron run" do
      expect { subject.perform }.to change { Quest.where(quest_type: :random, status: :active).count }.by(1)
    end
  end

  describe "cron-only scheduling" do
    context "when simulation is not running" do
      before { config.update!(running: false) }

      it "returns early without processing quests" do
        expect { subject.perform }.not_to change { config.reload.tick_count }
      end
    end
  end

  describe "artifact drops on quest success" do
    let!(:quest) { create(:quest, :active, danger_level: 5, progress: 0.99) }
    let!(:character) do
      create(:character, status: :on_quest, strength: 20, wisdom: 20, endurance: 20, level: 1, xp: 0)
    end

    before do
      create(:quest_membership, quest: quest, character: character)
      config.update!(progress_min: 0.05, progress_max: 0.1)
      # Force quest to complete successfully
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(1.0)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)
    end

    it "calls ArtifactDropService on quest success" do
      expect(ArtifactDropService).to receive(:call).with(quest)
      subject.perform
    end

    it "does not call ArtifactDropService when quest fails" do
      # Force failure by making rand(100.0) return a high number
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(100.0).and_return(99.0)
      allow_any_instance_of(QuestTickWorker).to receive(:rand).with(no_args).and_return(0.5)
      expect(ArtifactDropService).not_to receive(:call)
      subject.perform
    end
  end
end
