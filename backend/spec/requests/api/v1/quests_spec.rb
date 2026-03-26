# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Quests", type: :request do
  describe "GET /api/v1/quests" do
    let!(:quests) { create_list(:quest, 3) }

    it "returns HTTP 200" do
      get "/api/v1/quests"
      expect(response).to have_http_status(:ok)
    end

    it "returns all quests" do
      get "/api/v1/quests"
      expect(response.parsed_body.length).to eq(3)
    end

    it "filters by status" do
      create(:quest, :active)
      get "/api/v1/quests", params: { status: "active" }
      expect(response.parsed_body.all? { |q| q["status"] == "active" }).to be(true)
    end

    it "paginates" do
      get "/api/v1/quests", params: { per_page: 2 }
      expect(response.parsed_body.length).to eq(2)
    end

    it "sorts quests: active first, then pending, then completed, then failed" do
      Quest.delete_all
      failed_quest    = create(:quest, :failed,    title: "F quest", campaign_order: nil)
      completed_quest = create(:quest, :completed, title: "C quest", campaign_order: nil)
      pending_quest   = create(:quest,             title: "P quest", campaign_order: nil)
      active_quest    = create(:quest, :active,    title: "A quest", campaign_order: nil)

      get "/api/v1/quests"
      ids = response.parsed_body.map { |q| q["id"] }
      expect(ids.index(active_quest.id)).to be < ids.index(pending_quest.id)
      expect(ids.index(pending_quest.id)).to be < ids.index(completed_quest.id)
      expect(ids.index(completed_quest.id)).to be < ids.index(failed_quest.id)
    end

    it "orders pending quests by campaign_order within their group" do
      Quest.delete_all
      pending_b = create(:quest, title: "P-B", campaign_order: 2)
      pending_a = create(:quest, title: "P-A", campaign_order: 1)
      active    = create(:quest, :active, title: "Active", campaign_order: nil)

      get "/api/v1/quests"
      ids = response.parsed_body.map { |q| q["id"] }
      expect(ids.first).to eq(active.id)
      pending_ids = ids - [active.id]
      expect(pending_ids).to eq([pending_a.id, pending_b.id])
    end

    it "returns progress as a number, not a string" do
      get "/api/v1/quests"
      progress_values = response.parsed_body.map { |q| q["progress"] }
      expect(progress_values).to all(be_a(Numeric))
    end

    it "returns success_chance as a number or nil, not a string" do
      get "/api/v1/quests"
      success_chances = response.parsed_body.map { |q| q["success_chance"] }.compact
      expect(success_chances).to all(be_a(Numeric))
    end
  end

  describe "GET /api/v1/quests/:id" do
    let!(:quest) { create(:quest) }
    let!(:character) { create(:character) }

    before { create(:quest_membership, quest: quest, character: character) }

    it "returns HTTP 200" do
      get "/api/v1/quests/#{quest.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns the quest" do
      get "/api/v1/quests/#{quest.id}"
      expect(response.parsed_body["id"]).to eq(quest.id)
    end

    it "includes members" do
      get "/api/v1/quests/#{quest.id}"
      expect(response.parsed_body["members"]).to be_an(Array)
      expect(response.parsed_body["members"].first["id"]).to eq(character.id)
    end

    it "includes success_chance" do
      get "/api/v1/quests/#{quest.id}"
      expect(response.parsed_body).to have_key("success_chance")
    end

    it "returns progress as a number, not a string" do
      get "/api/v1/quests/#{quest.id}"
      expect(response.parsed_body["progress"]).to be_a(Numeric)
    end

    it "returns success_chance as a number, not a string" do
      get "/api/v1/quests/#{quest.id}"
      expect(response.parsed_body["success_chance"]).to be_a(Numeric)
    end

    it "returns 404 for unknown quest" do
      get "/api/v1/quests/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/quests" do
    let(:valid_params) { { quest: { title: "Destroy the Ring", danger_level: 10 } } }

    it "returns HTTP 201" do
      post "/api/v1/quests", params: valid_params
      expect(response).to have_http_status(:created)
    end

    it "creates a quest" do
      expect { post "/api/v1/quests", params: valid_params }
        .to change(Quest, :count).by(1)
    end

    it "returns 422 when title is missing" do
      post "/api/v1/quests", params: { quest: { danger_level: 5 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/quests/:id" do
    let!(:quest) { create(:quest) }

    it "returns HTTP 200" do
      patch "/api/v1/quests/#{quest.id}", params: { quest: { title: "New Title" } }
      expect(response).to have_http_status(:ok)
    end

    it "updates the quest" do
      patch "/api/v1/quests/#{quest.id}", params: { quest: { title: "New Title" } }
      expect(quest.reload.title).to eq("New Title")
    end

    it "returns members in the response" do
      character = create(:character)
      create(:quest_membership, quest: quest, character: character)
      patch "/api/v1/quests/#{quest.id}", params: { quest: { title: "New Title" } }
      expect(response.parsed_body["members"]).to be_an(Array)
      expect(response.parsed_body["members"].first["id"]).to eq(character.id)
    end

    it "returns 422 with invalid params" do
      patch "/api/v1/quests/#{quest.id}", params: { quest: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for unknown quest" do
      patch "/api/v1/quests/0", params: { quest: { title: "X" } }
      expect(response).to have_http_status(:not_found)
    end

    context "when transitioning from pending to active (quest start)" do
      let!(:idle_characters) { create_list(:character, 3, status: "idle") }

      it "creates QuestMembership records for idle characters" do
        expect {
          patch "/api/v1/quests/#{quest.id}", params: { quest: { status: "active" } }
        }.to change(QuestMembership, :count).by(3)
      end

      it "sets assigned characters to on_quest status" do
        patch "/api/v1/quests/#{quest.id}", params: { quest: { status: "active" } }
        assigned_ids = QuestMembership.where(quest: quest).pluck(:character_id)
        expect(Character.where(id: assigned_ids).pluck(:status).uniq).to eq(["on_quest"])
      end

      it "returns the assigned members in the response" do
        patch "/api/v1/quests/#{quest.id}", params: { quest: { status: "active" } }
        expect(response.parsed_body["members"]).to be_an(Array)
        expect(response.parsed_body["members"].length).to eq(3)
      end

      it "returns 422 when activating with no idle characters available" do
        Character.update_all(status: "on_quest")
        patch "/api/v1/quests/#{quest.id}", params: { quest: { status: "active" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to include(/must have at least one member/)
      end

      it "does not reassign characters that already have memberships" do
        existing_char = idle_characters.first
        create(:quest_membership, quest: quest, character: existing_char)

        expect {
          patch "/api/v1/quests/#{quest.id}", params: { quest: { status: "active" } }
        }.to change(QuestMembership, :count).by(2)
      end
    end

    context "when quest is already active" do
      let!(:active_quest) { create(:quest, :active) }

      it "does not auto-assign characters when updating a non-pending quest" do
        create_list(:character, 3, status: "idle")
        expect {
          patch "/api/v1/quests/#{active_quest.id}", params: { quest: { title: "Updated" } }
        }.not_to change(QuestMembership, :count)
      end
    end
  end

  describe "GET /api/v1/quests (index includes members)" do
    let!(:quest) { create(:quest) }
    let!(:character) { create(:character) }

    before { create(:quest_membership, quest: quest, character: character) }

    it "includes a members array for each quest" do
      get "/api/v1/quests"
      bodies = response.parsed_body
      expect(bodies).to all(have_key("members"))
    end

    it "populates members with assigned characters" do
      get "/api/v1/quests"
      quest_body = response.parsed_body.find { |q| q["id"] == quest.id }
      expect(quest_body["members"].first["id"]).to eq(character.id)
    end
  end

  describe "DELETE /api/v1/quests/:id" do
    let!(:quest) { create(:quest) }

    it "returns HTTP 204" do
      delete "/api/v1/quests/#{quest.id}"
      expect(response).to have_http_status(:no_content)
    end

    it "destroys the quest" do
      expect { delete "/api/v1/quests/#{quest.id}" }
        .to change(Quest, :count).by(-1)
    end
  end

  describe "POST /api/v1/quests/:id/members" do
    let!(:quest) { create(:quest, :active) }
    let!(:character) { create(:character) }

    it "returns HTTP 201" do
      post "/api/v1/quests/#{quest.id}/members",
           params: { character_id: character.id }
      expect(response).to have_http_status(:created)
    end

    it "adds the character to the quest" do
      expect {
        post "/api/v1/quests/#{quest.id}/members",
             params: { character_id: character.id }
      }.to change(QuestMembership, :count).by(1)
    end

    it "returns 422 if character is already on an active quest" do
      other_quest = create(:quest, :active)
      create(:quest_membership, character: character, quest: other_quest)
      post "/api/v1/quests/#{quest.id}/members",
           params: { character_id: character.id }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/quests/:id/members/:character_id" do
    let!(:quest) { create(:quest) }
    let!(:character) { create(:character) }
    let!(:membership) { create(:quest_membership, quest: quest, character: character) }

    it "returns HTTP 204" do
      delete "/api/v1/quests/#{quest.id}/members/#{character.id}"
      expect(response).to have_http_status(:no_content)
    end

    it "removes the character from the quest" do
      expect {
        delete "/api/v1/quests/#{quest.id}/members/#{character.id}"
      }.to change(QuestMembership, :count).by(-1)
    end
  end

  describe "GET /api/v1/quests/:id/events" do
    let!(:quest) { create(:quest) }
    let!(:events) { create_list(:quest_event, 3, quest: quest) }

    it "returns HTTP 200" do
      get "/api/v1/quests/#{quest.id}/events"
      expect(response).to have_http_status(:ok)
    end

    it "returns events for the quest" do
      get "/api/v1/quests/#{quest.id}/events"
      expect(response.parsed_body.length).to eq(3)
    end

    it "orders by created_at desc" do
      get "/api/v1/quests/#{quest.id}/events"
      times = response.parsed_body.map { |e| e["created_at"] }
      expect(times).to eq(times.sort.reverse)
    end
  end

  describe "POST /api/v1/quests/reset" do
    before do
      quest = create(:quest, status: "active", progress: 0.5, attempts: 2)
      character = create(:character, status: "on_quest")
      create(:quest_membership, quest: quest, character: character)
    end

    context "without confirm param" do
      it "returns unprocessable_entity" do
        post "/api/v1/quests/reset"
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with confirm: true" do
      it "resets all quests to pending" do
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(response).to have_http_status(:ok)
        expect(Quest.all.pluck(:status).uniq).to eq(["pending"])
        expect(Quest.all.pluck(:progress).map(&:to_f).uniq).to eq([0.0])
      end

      it "clears all quest memberships" do
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(QuestMembership.count).to eq(0)
      end

      it "sets all characters to idle" do
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(Character.all.pluck(:status).uniq).to eq(["idle"])
      end

      it "resets character level to 1 and xp to 0 on quest reset" do
        leveled_char = create(:character, level: 5, xp: 2000, status: "on_quest")
        post "/api/v1/quests/reset", params: { confirm: true }
        leveled_char.reload
        expect(leveled_char.level).to eq(1)
        expect(leveled_char.xp).to eq(0)
      end

      it "resets level to 1 and xp to 0 for multiple characters with different stats" do
        char_a = create(:character, level: 3, xp: 1000, status: "on_quest")
        char_b = create(:character, level: 7, xp: 5000, status: "idle")
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(char_a.reload.level).to eq(1)
        expect(char_a.reload.xp).to eq(0)
        expect(char_b.reload.level).to eq(1)
        expect(char_b.reload.xp).to eq(0)
      end

      it "returns level 1 and xp 0 for a character via the API after reset" do
        leveled_char = create(:character, level: 5, xp: 2000, status: "on_quest")
        post "/api/v1/quests/reset", params: { confirm: true }
        get "/api/v1/characters/#{leveled_char.id}"
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["level"]).to eq(1)
        expect(response.parsed_body["xp"]).to eq(0)
      end

      it "clears character_id on all artifacts after reset" do
        character = create(:character, status: "on_quest")
        create_list(:artifact, 3, character: character)
        expect(Artifact.where.not(character_id: nil).count).to eq(3)
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(Artifact.where.not(character_id: nil).count).to eq(0)
      end

      it "preserves artifact records but unlinks them from characters" do
        character = create(:character, status: "on_quest")
        create_list(:artifact, 2, character: character)
        artifact_count = Artifact.count
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(Artifact.count).to eq(artifact_count)
        expect(Artifact.all.pluck(:character_id).uniq).to eq([nil])
      end

      it "returns level 1 for fellowship members after reset and re-assignment" do
        leveled_char = create(:character, level: 5, xp: 2000, status: "idle")
        quest = create(:quest)
        post "/api/v1/quests/reset", params: { confirm: true }

        # Re-assign the character to simulate post-reset party assembly
        create(:quest_membership, quest: quest, character: leveled_char)
        get "/api/v1/quests/#{quest.id}"
        member = response.parsed_body["members"].find { |m| m["id"] == leveled_char.id }
        expect(member).not_to be_nil
        expect(member["level"]).to eq(1)
      end

      it "resets SimulationConfig campaign_position to 0" do
        SimulationConfig.current.update!(campaign_position: 15, tick_count: 212)
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(SimulationConfig.current.campaign_position).to eq(0)
      end

      it "resets SimulationConfig tick_count to 0" do
        SimulationConfig.current.update!(campaign_position: 15, tick_count: 212)
        post "/api/v1/quests/reset", params: { confirm: true }
        expect(SimulationConfig.current.tick_count).to eq(0)
      end

      it "enqueues QuestAutoStartWorker when simulation is running" do
        SimulationConfig.current.update!(running: true)
        expect(QuestAutoStartWorker).to receive(:perform_async)
        post "/api/v1/quests/reset", params: { confirm: true }
      end

      it "does not enqueue QuestAutoStartWorker when simulation is stopped" do
        SimulationConfig.current.update!(running: false)
        expect(QuestAutoStartWorker).not_to receive(:perform_async)
        post "/api/v1/quests/reset", params: { confirm: true }
      end
    end
  end

  describe "POST /api/v1/quests/randomize" do
    before do
      create_list(:quest, 3)
      create_list(:character, 6, status: "idle")
    end

    it "assigns characters to quests" do
      post "/api/v1/quests/randomize"
      expect(response).to have_http_status(:ok)
      expect(QuestMembership.count).to be > 0
    end

    it "returns a success message" do
      post "/api/v1/quests/randomize"
      json = JSON.parse(response.body)
      expect(json["message"]).to include("randomized")
      expect(json["count"]).to eq(3)
    end
  end
end
