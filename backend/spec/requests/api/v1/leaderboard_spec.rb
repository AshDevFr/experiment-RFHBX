# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Leaderboard", type: :request do
  describe "GET /api/v1/leaderboard" do
    let!(:high_level) { create(:character, level: 20, xp: 5000) }
    let!(:mid_level)  { create(:character, level: 10, xp: 1000) }
    let!(:low_level)  { create(:character, level: 1,  xp: 0) }

    it "returns HTTP 200" do
      get "/api/v1/leaderboard"
      expect(response).to have_http_status(:ok)
    end

    it "returns characters ranked by level desc, xp desc" do
      get "/api/v1/leaderboard"
      ids = response.parsed_body.map { |c| c["id"] }
      expect(ids).to eq([high_level.id, mid_level.id, low_level.id])
    end

    it "returns top 25 by default" do
      create_list(:character, 30)
      get "/api/v1/leaderboard"
      expect(response.parsed_body.length).to eq(25)
    end

    it "includes relevant character fields" do
      get "/api/v1/leaderboard"
      char = response.parsed_body.first
      expect(char.keys).to include("id", "name", "level", "xp", "status")
    end
  end
end
