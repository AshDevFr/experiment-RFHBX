# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::SimulationConfigType do
  subject(:type) { described_class }

  it "exposes the expected fields" do
    expected_fields = %w[
      id mode running
      progressMin progressMax campaignPosition
      createdAt updatedAt
    ]

    field_names = type.fields.keys
    expected_fields.each do |field|
      expect(field_names).to include(field), "Expected field '#{field}' to be defined on SimulationConfigType"
    end
  end

  it "marks all fields as non-null" do
    %w[id mode running progressMin progressMax campaignPosition createdAt updatedAt].each do |field|
      expect(type.fields[field].type.non_null?).to be true
    end
  end
end
