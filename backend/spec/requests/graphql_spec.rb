# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL endpoint", type: :request do
  describe "POST /graphql" do
    context "with a basic introspection query" do
      it "returns HTTP 200 with a valid JSON GraphQL response" do
        result = gql("{ __schema { queryType { name } } }")

        expect(response).to have_http_status(:ok)
        expect(result).to have_key("data")
        expect(result.dig("data", "__schema", "queryType", "name")).to eq("Query")
      end
    end

    context "with the health field" do
      it "returns ok" do
        result = gql("{ health }")

        expect(response).to have_http_status(:ok)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "health")).to eq("ok")
      end
    end

    context "with an invalid query" do
      it "returns a GraphQL error without raising an exception" do
        result = gql("{ nonExistentField }")

        expect(response).to have_http_status(:ok)
        expect(result["errors"]).to be_present
      end
    end
  end
end
