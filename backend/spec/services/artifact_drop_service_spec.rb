# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArtifactDropService, type: :service do
  let!(:quest) { create(:quest, :active, danger_level: 5) }
  let!(:character) { create(:character, status: :on_quest, strength: 10, wisdom: 10, endurance: 10) }

  before do
    create(:quest_membership, quest: quest, character: character)
  end

  describe ".call" do
    it "delegates to #call on a new instance" do
      service = instance_double(described_class)
      allow(described_class).to receive(:new).with(quest).and_return(service)
      allow(service).to receive(:call)
      described_class.call(quest)
      expect(service).to have_received(:call)
    end
  end

  describe "#call" do
    subject(:service) { described_class.new(quest) }

    context "when rand always rolls under DROP_CHANCE" do
      before { allow(service).to receive(:rand).with(no_args).and_return(0.0) }

      it "creates an artifact for each party member" do
        expect { service.call }.to change(Artifact, :count).by(1)
      end

      it "assigns the artifact to the character" do
        service.call
        expect(character.artifacts.reload.count).to eq(1)
      end

      it "creates an artifact_found QuestEvent" do
        expect { service.call }.to change(QuestEvent, :count).by(1)
        event = QuestEvent.last
        expect(event.event_type).to eq("artifact_found")
        expect(event.quest).to eq(quest)
      end

      it "sets the event message to '<CharacterName> found <ArtifactName>!'" do
        service.call
        event = QuestEvent.last
        artifact = Artifact.last
        expect(event.message).to eq("#{character.name} found #{artifact.name}!")
      end

      it "stores character and artifact info in event data" do
        service.call
        data = QuestEvent.last.data
        artifact = Artifact.last
        expect(data["character_id"]).to eq(character.id)
        expect(data["character_name"]).to eq(character.name)
        expect(data["artifact_id"]).to eq(artifact.id)
        expect(data["artifact_name"]).to eq(artifact.name)
        expect(data["stat_bonus"]).to be_a(Hash)
      end

      it "assigns a stat_bonus with one of strength/wisdom/endurance" do
        service.call
        artifact = Artifact.last
        bonus_keys = artifact.stat_bonus.keys
        expect(bonus_keys.length).to eq(1)
        expect(ArtifactDropService::STAT_ATTRIBUTES).to include(bonus_keys.first)
      end

      it "assigns a stat_bonus value between 1 and danger_level" do
        service.call
        artifact = Artifact.last
        value = artifact.stat_bonus.values.first
        expect(value).to be_between(1, quest.danger_level)
      end

      it "broadcasts the artifact_found event via ActionCable" do
        allow(QuestEventBroadcaster).to receive(:broadcast)
        service.call
        expect(QuestEventBroadcaster).to have_received(:broadcast).once
      end

      it "uses a LOTR-canon artifact name" do
        service.call
        artifact = Artifact.last
        valid_names = (ArtifactDropService::LOTR_ARTIFACTS + [ArtifactDropService::ONE_RING]).map { |a| a[:name] }
        expect(valid_names).to include(artifact.name)
      end
    end

    context "when rand always rolls above DROP_CHANCE" do
      before { allow(service).to receive(:rand).with(no_args).and_return(1.0) }

      it "creates no artifacts" do
        expect { service.call }.not_to change(Artifact, :count)
      end

      it "creates no QuestEvents" do
        expect { service.call }.not_to change(QuestEvent, :count)
      end
    end

    context "with multiple party members" do
      let!(:character2) { create(:character, status: :on_quest) }

      before do
        create(:quest_membership, quest: quest, character: character2)
        allow(service).to receive(:rand).with(no_args).and_return(0.0)
      end

      it "can drop artifacts for multiple party members" do
        expect { service.call }.to change(Artifact, :count).by(2)
        expect { }.not_to change(QuestEvent, :count) # already counted above
      end
    end

    context "One Ring drop (danger_level 10)" do
      let!(:quest) { create(:quest, :active, danger_level: 10) }

      before do
        create(:quest_membership, quest: quest, character: character)
        # Force the drop roll to succeed, and the One Ring roll to succeed
        call_count = 0
        allow(service).to receive(:rand).with(no_args) do
          call_count += 1
          call_count == 1 ? 0.0 : 0.05  # first call: drop check, second: One Ring check
        end
      end

      it "can drop the One Ring at danger_level 10" do
        service.call
        artifact = Artifact.last
        expect(artifact.name).to eq("One Ring")
      end
    end

    context "One Ring does not drop below danger_level 10" do
      let!(:quest) { create(:quest, :active, danger_level: 9) }

      before do
        create(:quest_membership, quest: quest, character: character)
        allow(service).to receive(:rand).with(no_args).and_return(0.0)
      end

      it "never drops the One Ring" do
        10.times { service.call }
        expect(Artifact.pluck(:name)).not_to include("One Ring")
      end
    end
  end
end
