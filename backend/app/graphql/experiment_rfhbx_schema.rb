# frozen_string_literal: true

class ExperimentRfhbxSchema < GraphQL::Schema
  query Types::QueryType
  mutation Types::MutationType

  # Prevent runaway queries
  max_depth 10
  max_complexity 300

  # Use the default error handler
  rescue_from(ActiveRecord::RecordNotFound) do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError, err.message
  end
end
