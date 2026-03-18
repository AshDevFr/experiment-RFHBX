# frozen_string_literal: true

Rswag::Api.configure do |c|
  # Directory where swagger spec files are stored
  c.openapi_root = Rails.root.join("swagger").to_s
end
