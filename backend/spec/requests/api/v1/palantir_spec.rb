# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Palantir", type: :request do
  describe "POST /api/v1/palantir/send" do
    it "returns HTTP 202" do
      post "/api/v1/palantir/send", params: { message: "All shall be lost!" }
      expect(response).to have_http_status(:accepted)
    end

    it "returns a queued status" do
      post "/api/v1/palantir/send", params: { message: "The Eye sees all" }
      expect(response.parsed_body["status"]).to eq("queued")
    end

    it "returns 422 when message is blank" do
      post "/api/v1/palantir/send", params: { message: "" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when message is missing" do
      post "/api/v1/palantir/send"
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
