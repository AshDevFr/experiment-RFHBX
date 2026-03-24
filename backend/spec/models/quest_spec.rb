# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quest, type: :model do
  subject(:quest) { build(:quest) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_numericality_of(:danger_level).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(10) }
    it { is_expected.to validate_numericality_of(:attempts).is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { is_expected.to have_many(:quest_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:characters).through(:quest_memberships) }
    it { is_expected.to have_many(:quest_events).dependent(:destroy) }
  end

  describe "defaults" do
    subject(:quest) { Quest.new(title: "Destroy the One Ring") }

    it "defaults status to pending" do
      expect(quest.status).to eq("pending")
    end

    it "defaults progress to 0.0" do
      expect(quest.progress).to eq(0.0)
    end

    it "defaults quest_type to campaign" do
      expect(quest.quest_type).to eq("campaign")
    end

    it "defaults attempts to 0" do
      expect(quest.attempts).to eq(0)
    end
  end

  describe "enum" do
    it "defines pending status" do
      quest = build(:quest, status: :pending)
      expect(quest).to be_pending
    end

    it "defines active status" do
      quest = build(:quest, status: :active)
      expect(quest).to be_active
    end

    it "defines completed status" do
      quest = build(:quest, status: :completed)
      expect(quest).to be_completed
    end

    it "defines failed status" do
      quest = build(:quest, status: :failed)
      expect(quest).to be_failed
    end

    it "defines campaign quest_type" do
      quest = build(:quest, quest_type: :campaign)
      expect(quest).to be_campaign
    end

    it "defines random quest_type" do
      quest = build(:quest, quest_type: :random)
      expect(quest).to be_random
    end
  end

  describe "must_have_at_least_one_member_when_active validation" do
    context "when quest is persisted and active" do
      let(:quest) { create(:quest, :active) }

      it "is invalid when it has no members" do
        expect(quest).not_to be_valid
        expect(quest.errors[:base]).to include("must have at least one member to be active")
      end

      it "is valid when it has at least one member" do
        create(:quest_membership, quest: quest)
        expect(quest).to be_valid
      end
    end

    context "when quest is a new record" do
      it "allows creating an active quest without members (members added post-creation)" do
        quest = Quest.new(
          title: "Test Quest",
          status: :active,
          danger_level: 5
        )
        # new_record? is true — validation is skipped so it only fires on subsequent saves
        expect(quest.valid?).to be true
      end
    end

    context "when quest is not active" do
      it "allows a pending quest with no members" do
        quest = create(:quest, status: :pending)
        expect(quest).to be_valid
      end

      it "allows a completed quest with no members" do
        quest = create(:quest, :completed)
        expect(quest).to be_valid
      end

      it "allows a failed quest with no members" do
        quest = create(:quest, :failed)
        expect(quest).to be_valid
      end
    end

    context "activating a memberless quest via update" do
      it "rejects updating a pending memberless quest to active" do
        quest = create(:quest, status: :pending)
        quest.status = :active
        expect(quest).not_to be_valid
        expect(quest.errors[:base]).to include("must have at least one member to be active")
      end
    end
  end

  describe "factory" do
    it "creates a valid quest" do
      expect(create(:quest)).to be_persisted
    end

    it "creates an active quest with the active trait" do
      quest = create(:quest, :active)
      expect(quest.status).to eq("active")
    end

    it "creates a random quest with the random_quest trait" do
      quest = create(:quest, :random_quest)
      expect(quest.quest_type).to eq("random")
    end
  end
end
