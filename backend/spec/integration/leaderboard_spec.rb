# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Leaderboard", type: :request do
  path "/api/v1/leaderboard" do
    get "Get the leaderboard" do
      tags "Leaderboard"
      operationId "getLeaderboard"
      produces "application/json"
      description "Returns the top characters ranked by level (descending) then XP (descending)."

      parameter name: :per_page, in: :query, schema: { type: :integer, example: 25 },
                required: false, description: "Number of entries to return (max: 100, default: 25)"

      response "200", "leaderboard retrieved" do
        schema type: :array, items: { "$ref" => "#/components/schemas/LeaderboardEntry" }
        before { create_list(:character, 3) }
        run_test!
      end
    end
  end
end
