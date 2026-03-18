# frozen_string_literal: true

require "yaml"

module Api
  class DocsController < ApplicationController
    # GET /api/docs.json
    # Serves the OpenAPI spec as JSON
    def spec
      spec_path = Rails.root.join("swagger", "v1", "swagger.yaml")
      if spec_path.exist?
        render json: YAML.safe_load(spec_path.read)
      else
        render json: { error: "OpenAPI spec not found" }, status: :not_found
      end
    end

    # GET /api/docs
    # Serves Scalar interactive API docs
    def ui
      render body: scalar_html, content_type: "text/html"
    end

    private

    def scalar_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>Mordor's Edge API Docs</title>
          </head>
          <body>
            <script
              id="api-reference"
              data-url="/api/docs.json"
              data-configuration='{"theme":"default"}'
            ></script>
            <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
          </body>
        </html>
      HTML
    end
  end
end
