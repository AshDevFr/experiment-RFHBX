# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Palantir", type: :request do
  describe "POST /api/v1/palantir/send" do
    before do
      # Stub Shoryuken's SQS enqueue so no real AWS calls are made in tests
      allow(PalantirWorker).to receive(:perform_async)
    end

    it "returns HTTP 202" do
      post "/api/v1/palantir/send", params: { message: "All shall be lost!" }
      expect(response).to have_http_status(:accepted)
    end

    it "returns queued: true" do
      post "/api/v1/palantir/send", params: { message: "The Eye sees all" }
      expect(response.parsed_body["queued"]).to be(true)
    end

    it "enqueues the message to Shoryuken" do
      expect(PalantirWorker).to receive(:perform_async).with(
        { "message" => "Speak, friend" }.to_json
      )
      post "/api/v1/palantir/send", params: { message: "Speak, friend" }
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
