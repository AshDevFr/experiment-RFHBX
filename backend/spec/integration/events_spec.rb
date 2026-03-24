# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Events", type: :request do
  path "/api/v1/events" do
    get "List all events" do
      tags "Events"
      operationId "listEvents"
      produces "application/json"
      description "Returns a paginated list of quest events across all quests. " \
                  "Supports filtering by event_type, quest_id, and quest_title."

      parameter name: :event_type, in: :query,
                schema: { type: :string, enum: %w[started progress completed failed restarted] },
                required: false, description: "Filter by event type"
      parameter name: :quest_id, in: :query, schema: { type: :integer },
                required: false, description: "Filter events by quest ID"
      parameter name: :quest_title, in: :query, schema: { type: :string },
                required: false, description: "Filter events by quest title (case-insensitive partial match)"
      parameter name: :page, in: :query, schema: { type: :integer, example: 1 },
                required: false, description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, schema: { type: :integer, example: 25 },
                required: false, description: "Results per page (max: 100, default: 25)"

      response "200", "events retrieved" do
        schema "$ref" => "#/components/schemas/EventsResponse"

        before do
          quest = create(:quest)
          create_list(:quest_event, 2, quest: quest)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key("events")
          expect(data).to have_key("meta")
          expect(data["meta"]).to include("total", "page", "per_page", "total_pages")
          expect(data["events"].first).to have_key("quest_title")
        end
      end

      response "200", "filtered by event_type" do
        schema "$ref" => "#/components/schemas/EventsResponse"

        let(:event_type) { "started" }

        before do
          quest = create(:quest)
          create(:quest_event, quest: quest, event_type: :started)
          create(:quest_event, quest: quest, event_type: :completed)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["events"].map { |e| e["event_type"] }.uniq).to eq(["started"])
        end
      end

      response "200", "filtered by quest_title" do
        schema "$ref" => "#/components/schemas/EventsResponse"

        let(:quest_title) { "Ring" }

        before do
          ring_quest  = create(:quest, title: "Destroy the One Ring")
          other_quest = create(:quest, title: "Scout the Shire")
          create(:quest_event, quest: ring_quest)
          create(:quest_event, quest: other_quest)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["events"].map { |e| e["quest_title"] }.uniq).to eq(["Destroy the One Ring"])
        end
      end

      response "200", "paginated results" do
        schema "$ref" => "#/components/schemas/EventsResponse"

        let(:per_page) { 1 }

        before do
          quest = create(:quest)
          create_list(:quest_event, 3, quest: quest)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["events"].length).to eq(1)
          expect(data["meta"]["total"]).to eq(3)
          expect(data["meta"]["total_pages"]).to eq(3)
        end
      end
    end
  end
end
