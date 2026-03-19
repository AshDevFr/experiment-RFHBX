# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL — QueryType introspection", type: :request do
  it "lists all expected query fields via __schema introspection" do
    result = gql("{ __schema { queryType { fields { name } } } }")

    expect(result["errors"]).to be_nil
    field_names = result.dig("data", "__schema", "queryType", "fields").map { |f| f["name"] }

    expected_fields = %w[
      health
      characters character
      quests quest
      artifacts artifact
      questMemberships
      simulationConfig
    ]

    expected_fields.each do |field|
      expect(field_names).to include(field), "Expected query field '#{field}' to be listed in introspection"
    end
  end
end
