# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimulationConfig, type: :model do
  describe "validations" do
    it { is_expected.to validate_numericality_of(:tick_count).is_greater_than_or_equal_to(0) }
  end

  describe "defaults" do
    subject(:config) { SimulationConfig.new }

    it "defaults mode to campaign" do
      expect(config.mode).to eq("campaign")
    end

    it "defaults running to false" do
      expect(config.running).to be false
    end

    it "defaults progress_min to 0.01" do
      expect(config.progress_min).to eq(0.01)
    end

    it "defaults progress_max to 0.1" do
      expect(config.progress_max).to eq(0.1)
    end

    it "defaults campaign_position to 0" do
      expect(config.campaign_position).to eq(0)
    end
  end

  describe "enum" do
    it "defines campaign mode" do
      config = build(:simulation_config, mode: :campaign)
      expect(config).to be_campaign
    end

    it "defines random mode" do
      config = build(:simulation_config, mode: :random)
      expect(config).to be_random
    end
  end

  describe "singleton enforcement" do
    it "allows creating the first instance" do
      config = build(:simulation_config)
      expect(config).to be_valid
    end

    it "rejects creating a second instance" do
      create(:simulation_config)
      second = build(:simulation_config)
      expect(second).not_to be_valid
      expect(second.errors[:base]).to include("only one SimulationConfig can exist")
    end

    it "allows updating the existing instance" do
      config = create(:simulation_config)
      config.progress_min = 0.05
      expect(config).to be_valid
    end
  end

  describe ".current" do
    it "returns the existing config if present" do
      config = create(:simulation_config)
      expect(SimulationConfig.current).to eq(config)
    end

    it "creates and returns a new config if none exists" do
      expect(SimulationConfig.current).to be_persisted
    end
  end

  describe "factory" do
    it "creates a valid simulation config" do
      expect(create(:simulation_config)).to be_persisted
    end
  end
end
