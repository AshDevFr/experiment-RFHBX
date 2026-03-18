# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Health", type: :request do
  path "/api/health" do
    get "Check API health" do
      tags "Health"
      operationId "getHealth"
      produces "application/json"
      description "Returns the API status, version, and environment. Useful for liveness probes."

      response "200", "API is healthy" do
        schema "$ref" => "#/components/schemas/HealthStatus"
        run_test!
      end
    end
  end
end
