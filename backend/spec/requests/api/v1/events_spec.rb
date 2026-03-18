# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let!(:quest) { create(:quest) }
  let!(:events) { create_list(:quest_event, 3, quest: quest) }

  describe "GET /api/v1/events" do
    it "returns HTTP 200" do
      get "/api/v1/events"
      expect(response).to have_http_status(:ok)
    end

    it "returns all events" do
      get "/api/v1/events"
      expect(response.parsed_body.length).to eq(3)
    end

    it "filters by event_type" do
      get "/api/v1/events", params: { event_type: "started" }
      expect(response.parsed_body.all? { |e| e["event_type"] == "started" }).to be(true)
    end

    it "filters by quest_id" do
      other_quest = create(:quest)
      create(:quest_event, quest: other_quest, event_type: :progress)
      get "/api/v1/events", params: { quest_id: quest.id }
      expect(response.parsed_body.length).to eq(3)
    end

    it "paginates" do
      get "/api/v1/events", params: { per_page: 2 }
      expect(response.parsed_body.length).to eq(2)
    end
  end
end
