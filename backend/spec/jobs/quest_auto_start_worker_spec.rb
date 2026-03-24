# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestAutoStartWorker, type: :job do
  subject(:worker) { described_class.new }

  let(:config) { SimulationConfig.current }

  before do
    SimulationConfig.destroy_all
    config.update!(running: true)

    # Release any lingering lock between examples.
    Sidekiq.redis { |r| r.del(described_class::LOCK_KEY) }
  end

  # ── Basic guard conditions ──────────────────────────────────────────────────

  describe "simulation not running" do
    before { config.update!(running: false) }

    it "does nothing" do
      expect { worker.perform }.not_to change(QuestEvent, :count)
    end

    it "does not start any quest" do
      worker.perform
      expect(Quest.where(status: :active).count).to eq(0)
    end
  end

  # ── Idempotency / duplicate-start guard ────────────────────────────────────

  describe "idempotency in campaign mode" do
    before { config.update!(mode: :campaign) }

    it "does not start a second campaign quest when one is already active" do
      create(:quest, quest_type: :campaign, status: :active, campaign_order: 1)
      create(:quest, quest_type: :campaign, status: :pending, campaign_order: 2)

      expect { worker.perform }.not_to change(Quest.where(status: :active), :count)
    end
  end

  describe "idempotency in random mode" do
    before { config.update!(mode: :random) }

    it "does not start a second random quest when one is already active" do
      create(:quest, quest_type: :random, status: :active)
      create_list(:character, 3, status: :idle)

      expect { worker.perform }.not_to change(Quest.where(quest_type: :random, status: :active), :count)
    end
  end

  describe "Redis lock prevents concurrent starts" do
    before { config.update!(mode: :campaign) }

    it "returns without starting a quest when the lock is already held" do
      create(:quest, quest_type: :campaign, status: :pending, campaign_order: 1)

      # Simulate another worker instance already holding the lock.
      Sidekiq.redis { |r| r.set(described_class::LOCK_KEY, 1, nx: true, ex: described_class::LOCK_TTL) }

      expect { worker.perform }.not_to change(Quest.where(status: :active), :count)
    end

    it "releases the lock after a successful run" do
      create(:quest, quest_type: :campaign, status: :pending, campaign_order: 1)
      create_list(:character, 2, status: :idle)

      worker.perform

      held = Sidekiq.redis { |r| r.exists(described_class::LOCK_KEY) }
      expect(held).to eq(0)
    end
  end

  # ── Campaign mode ───────────────────────────────────────────────────────────

  describe "campaign mode — auto-start" do
    before { config.update!(mode: :campaign) }

    let!(:quest1) do
      create(:quest, quest_type: :campaign, campaign_order: 1, status: :pending, danger_level: 3)
    end
    let!(:quest2) do
      create(:quest, quest_type: :campaign, campaign_order: 2, status: :pending, danger_level: 5)
    end

    it "activates the next pending campaign quest" do
      create_list(:character, 2, status: :idle)
      worker.perform
      expect(quest1.reload.status).to eq("active")
    end

    it "does not activate the second quest yet" do
      create_list(:character, 2, status: :idle)
      worker.perform
      expect(quest2.reload.status).to eq("pending")
    end

    it "assigns idle characters to the campaign quest" do
      create_list(:character, 3, status: :idle)
      worker.perform
      expect(quest1.reload.quest_memberships.count).to be >= 1
    end

    it "sets assigned characters to on_quest" do
      create_list(:character, 3, status: :idle)
      worker.perform
      quest1.reload.characters.each do |c|
        expect(c.reload.status).to eq("on_quest")
      end
    end

    it "creates a :started QuestEvent" do
      create_list(:character, 2, status: :idle)
      worker.perform
      event = QuestEvent.find_by(quest: quest1, event_type: :started)
      expect(event).to be_present
    end

    it "updates campaign_position on the config" do
      create_list(:character, 2, status: :idle)
      worker.perform
      expect(config.reload.campaign_position).to eq(1)
    end

    it "defers activation when no idle characters are available" do
      # No characters — quest cannot be activated without a party; it stays pending
      # until idle characters become available on a subsequent tick.
      worker.perform
      expect(quest1.reload.status).to eq("pending")
    end
  end

  describe "campaign mode — all quests completed, switches to random" do
    before do
      config.update!(mode: :campaign)
      create(:quest, quest_type: :campaign, campaign_order: 1, status: :completed)
    end

    it "switches config to random mode" do
      worker.perform
      expect(config.reload.mode).to eq("random")
    end

    it "immediately starts a random quest when idle characters are available" do
      create_list(:character, 3, status: :idle)

      expect { worker.perform }.to change { Quest.where(quest_type: :random, status: :active).count }.by(1)
    end

    it "does not leave the simulation questless after campaign completion" do
      create_list(:character, 3, status: :idle)
      worker.perform
      expect(Quest.where(status: :active).count).to eq(1)
    end
  end

  # ── Random mode ─────────────────────────────────────────────────────────────

  describe "random mode — auto-start" do
    before do
      config.update!(mode: :random)
      Quest.where(quest_type: :campaign).destroy_all
    end

    it "generates a new random quest when none is active" do
      create_list(:character, 3, status: :idle)
      expect { worker.perform }.to change { Quest.where(quest_type: :random).count }.by(1)
    end

    it "activates the generated quest" do
      create_list(:character, 3, status: :idle)
      worker.perform
      quest = Quest.where(quest_type: :random).last
      expect(quest.status).to eq("active")
    end

    it "assigns 2-4 idle characters to the quest" do
      create_list(:character, 4, status: :idle)
      worker.perform
      quest = Quest.where(quest_type: :random, status: :active).last
      expect(quest.characters.count).to be_between(2, 4)
    end

    it "creates a :started QuestEvent for the random quest" do
      create_list(:character, 3, status: :idle)
      worker.perform
      quest = Quest.where(quest_type: :random).last
      event = QuestEvent.find_by(quest: quest, event_type: :started)
      expect(event).to be_present
    end

    it "does not generate a quest when fewer than 2 idle characters exist" do
      create(:character, status: :idle)
      expect { worker.perform }.not_to change { Quest.where(quest_type: :random).count }
    end
  end

  # ── Boot-time trigger: enqueued on Sidekiq startup ─────────────────────────

  describe "enqueueing via perform_async (Sidekiq fake mode)" do
    it "can be enqueued without error" do
      expect { described_class.perform_async }.to change(described_class.jobs, :size).by(1)
    end
  end
end
