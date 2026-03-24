# frozen_string_literal: true

require "rails_helper"

# Seeds the database before each example so that transactional fixtures handle
# cleanup automatically. Using before(:each) instead of before(:all) avoids
# data leaking across spec files — before(:all) runs outside the per-example
# transaction, so its records persist and pollute other specs (e.g. count
# assertions and singleton validations). The trade-off is that seeds load once
# per example, but the seed file is fast (~60 records) and correctness matters
# more than a few extra milliseconds.
RSpec.describe "db/seeds", type: :model do
  before do
    load Rails.root.join("db/seeds.rb")
  end

  describe "Character seeds" do
    it "creates at least 25 characters" do
      expect(Character.count).to be >= 25
    end

    it "includes all Fellowship members" do
      fellowship = %w[
        Aragorn Gandalf Legolas Gimli Boromir
      ] + ["Frodo Baggins", "Samwise Gamgee", "Pippin", "Merry"]

      fellowship.each do |name|
        expect(Character.find_by(name: name)).to be_present, "Expected to find character: #{name}"
      end
    end

    it "sets Frodo as ring bearer" do
      frodo = Character.find_by!(name: "Frodo Baggins")
      expect(frodo.ring_bearer).to be true
    end

    it "gives Gandalf the highest wisdom" do
      gandalf = Character.find_by!(name: "Gandalf")
      expect(gandalf.wisdom).to eq 20
    end

    it "seeds all characters with valid status values" do
      valid_statuses = Character.statuses.keys
      Character.find_each do |c|
        expect(valid_statuses).to include(c.status), "#{c.name} has invalid status: #{c.status}"
      end
    end
  end

  describe "Quest seeds" do
    it "creates at least 10 quests" do
      expect(Quest.count).to be >= 10
    end

    it "includes 'Destroy the One Ring'" do
      expect(Quest.find_by(title: "Destroy the One Ring")).to be_present
    end

    it "assigns campaign_order to every campaign quest" do
      Quest.where(quest_type: "campaign").find_each do |q|
        expect(q.campaign_order).to be_present, "#{q.title} missing campaign_order"
      end
    end

    it "has 'Destroy the One Ring' at danger_level 10" do
      quest = Quest.find_by!(title: "Destroy the One Ring")
      expect(quest.danger_level).to eq 10
    end

    it "has unique campaign_order values" do
      orders = Quest.where(quest_type: "campaign").pluck(:campaign_order).compact
      expect(orders).to eq orders.uniq
    end
  end

  describe "Artifact seeds" do
    it "creates at least 16 artifacts" do
      expect(Artifact.count).to be >= 16
    end

    it "marks The One Ring as corrupted" do
      ring = Artifact.find_by!(name: "The One Ring")
      expect(ring.corrupted).to be true
    end

    it "gives The One Ring a strength bonus" do
      ring = Artifact.find_by!(name: "The One Ring")
      expect(ring.stat_bonus["strength"]).to eq 5
    end

    it "gives The One Ring a negative wisdom bonus (corrupting)" do
      ring = Artifact.find_by!(name: "The One Ring")
      expect(ring.stat_bonus["wisdom"]).to be_negative
    end

    it "gives the Mithril Coat an endurance bonus" do
      coat = Artifact.find_by!(name: "Mithril Coat")
      expect(coat.stat_bonus["endurance"]).to eq 5
    end

    it "assigns The One Ring to Frodo" do
      frodo = Character.find_by!(name: "Frodo Baggins")
      ring  = Artifact.find_by!(name: "The One Ring")
      expect(ring.character_id).to eq frodo.id
    end

    it "seeds all artifacts with string keys in stat_bonus" do
      Artifact.find_each do |a|
        a.stat_bonus.each_key do |k|
          expect(k).to be_a(String), "#{a.name} has non-string key in stat_bonus: #{k.inspect}"
        end
      end
    end
  end

  describe "QuestMembership seeds" do
    it "assigns the Fellowship to 'Destroy the One Ring'" do
      quest = Quest.find_by!(title: "Destroy the One Ring")
      expect(quest.characters.count).to eq 9
    end

    it "gives Frodo the Ring Bearer role" do
      frodo = Character.find_by!(name: "Frodo Baggins")
      quest = Quest.find_by!(title: "Destroy the One Ring")
      membership = QuestMembership.find_by!(character: frodo, quest: quest)
      expect(membership.role).to eq "Ring Bearer"
    end

    it "gives Gandalf the Guide role" do
      gandalf = Character.find_by!(name: "Gandalf")
      quest   = Quest.find_by!(title: "Destroy the One Ring")
      membership = QuestMembership.find_by!(character: gandalf, quest: quest)
      expect(membership.role).to eq "Guide"
    end

    it "gives Sam the Companion role" do
      sam   = Character.find_by!(name: "Samwise Gamgee")
      quest = Quest.find_by!(title: "Destroy the One Ring")
      membership = QuestMembership.find_by!(character: sam, quest: quest)
      expect(membership.role).to eq "Companion"
    end
  end

  describe "SimulationConfig seeds" do
    it "creates exactly one SimulationConfig" do
      expect(SimulationConfig.count).to eq 1
    end

    it "defaults to campaign mode" do
      expect(SimulationConfig.current.mode).to eq "campaign"
    end

    it "seeds with running enabled so Sidekiq workers process quests" do
      expect(SimulationConfig.current.running).to be true
    end

    it "sets a positive tick_interval_seconds" do
      expect(SimulationConfig.current.tick_interval_seconds).to be_positive
    end
  end

  describe "idempotency" do
    it "does not create duplicates when seeded twice" do
      character_count_before = Character.count
      quest_count_before     = Quest.count
      artifact_count_before  = Artifact.count

      load Rails.root.join("db/seeds.rb")

      expect(Character.count).to eq character_count_before
      expect(Quest.count).to eq quest_count_before
      expect(Artifact.count).to eq artifact_count_before
    end
  end
end
