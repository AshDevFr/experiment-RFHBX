# frozen_string_literal: true

# Stub the Shoryuken SQS client for tests so no real AWS credentials
# or network connections are required.
#
# In individual specs that test the worker directly, call #perform on the
# worker instance. For endpoint specs, stub PalantirWorker.perform_async.

RSpec.configure do |config|
  config.before(:suite) do
    # Configure a stubbed SQS client — all API calls return empty successful responses
    Aws.config.update(stub_responses: true)

    # Point Shoryuken at a fake SQS client so initializer doesn't error
    Shoryuken.configure_client do |shoryuken_config|
      shoryuken_config.sqs_client = Aws::SQS::Client.new(
        region:            "us-east-1",
        access_key_id:     "test",
        secret_access_key: "test",
        stub_responses:    true
      )
    end
  end
end
