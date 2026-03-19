# frozen_string_literal: true

# ── Shoryuken / SQS configuration ─────────────────────────────────────────────
# In production/staging, set real AWS credentials via environment variables.
# For local development, ElasticMQ is used as a drop-in SQS replacement.
# In tests, the SQS client is stubbed — no real AWS credentials required.
#
# NOTE: `endpoint:` is omitted (via .compact) when SQS_ENDPOINT is not set so
# the AWS SDK does not raise ArgumentError for a nil endpoint in CI.

Shoryuken.configure_client do |config|
  config.sqs_client = Aws::SQS::Client.new(
    {
      region:            ENV.fetch("AWS_REGION", "us-east-1"),
      access_key_id:     ENV.fetch("AWS_ACCESS_KEY_ID", "dummy"),
      secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY", "dummy"),
      endpoint:          ENV["SQS_ENDPOINT"],
    }.compact
  )
end

Shoryuken.configure_server do |config|
  config.sqs_client = Aws::SQS::Client.new(
    {
      region:            ENV.fetch("AWS_REGION", "us-east-1"),
      access_key_id:     ENV.fetch("AWS_ACCESS_KEY_ID", "dummy"),
      secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY", "dummy"),
      endpoint:          ENV["SQS_ENDPOINT"],
    }.compact
  )
end
