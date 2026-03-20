# frozen_string_literal: true

class GraphqlController < ApplicationController
  # Skip JWT authentication for GraphQL introspection in development
  # so the GraphiQL playground remains usable without a token.
  skip_before_action :authenticate_request!, if: -> { Rails.env.development? && introspection_query? }

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_principal: current_principal
    }
    result = ExperimentRfhbxSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

  def introspection_query?
    query = params[:query].to_s
    query.include?("__schema") || query.include?("__type")
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will handle these as a hash
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(err)
    logger.error err.message
    logger.error err.backtrace.join("\n")

    render json: { errors: [{ message: err.message, backtrace: err.backtrace }], data: {} }, status: :internal_server_error
  end
end
