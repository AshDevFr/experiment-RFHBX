# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Palantir", type: :request do
  path "/api/v1/palantir/send" do
    post "Send a Palantir message" do
      tags "Palantir"
      operationId "sendPalantirMessage"
      consumes "application/json"
      produces "application/json"
      description "Dispatches an asynchronous message via the Palantir (the seeing-stone). " \
                  "The message is enqueued to SQS (via Shoryuken) for background processing."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:message],
        properties: {
          message: {
            type: :string,
            description: "The message to dispatch through the Palantir",
            example: "The Eye of Sauron has turned toward Gondor."
          }
        }
      }

      response "202", "message queued" do
        schema "$ref" => "#/components/schemas/QueuedResponse"
        let(:body) { { message: "Fly, you fools!" } }
        before { allow(PalantirWorker).to receive(:perform_async) }
        run_test!
      end

      response "422", "message is blank" do
        schema "$ref" => "#/components/schemas/ErrorResponse"
        let(:body) { { message: "" } }
        run_test!
      end
    end
  end
end
