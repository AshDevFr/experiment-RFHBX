# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Events", type: :request do
  path "/api/v1/events" do
    get "List all events" do
      tags "Events"
      operationId "listEvents"
      produces "application/json"
      description "Returns a paginated list of quest events across all quests. Supports filtering by event_type and quest_id."

      parameter name: :event_type, in: :query,
                schema: { type: :string, enum: %w[started progress completed failed restarted] },
                required: false, description: "Filter by event type"
      parameter name: :quest_id, in: :query, schema: { type: :integer },
                required: false, description: "Filter events by quest"
      parameter name: :page, in: :query, schema: { type: :integer, example: 1 },
                required: false, description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, schema: { type: :integer, example: 25 },
                required: false, description: "Results per page (max: 100, default: 25)"

      response "200", "events retrieved" do
        schema type: :array, items: { "$ref" => "#/components/schemas/QuestEvent" }
        before do
          quest = create(:quest)
          create_list(:quest_event, 2, quest: quest)
        end
        run_test!
      end
    end
  end
end
