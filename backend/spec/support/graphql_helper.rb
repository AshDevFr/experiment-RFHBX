# frozen_string_literal: true

# Helper for GraphQL request specs.
#
# Usage:
#   include GraphqlHelper
#
#   result = gql("{ health }")
#   expect(result.dig("data", "health")).to eq("ok")
#
# Or with variables:
#   result = gql("query($id: ID!) { ... }", variables: { id: 1 })
module GraphqlHelper
  def gql(query, variables: {}, operation_name: nil)
    payload = { query: query, variables: variables }
    payload[:operationName] = operation_name if operation_name

    post "/graphql",
         params: payload.to_json,
         headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }

    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include GraphqlHelper, type: :request
end
