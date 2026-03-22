# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # Action Cable WebSocket endpoint
  mount ActionCable.server => "/cable"

  # OpenAPI spec (JSON) and Scalar interactive docs
  get "/api/docs",      to: "api/docs#ui",   format: false
  get "/api/docs.json", to: "api/docs#spec",  format: false

  # rswag-api engine (serves swagger files from swagger/)
  mount Rswag::Api::Engine => "/api-docs"

  # Sidekiq Web UI — protected behind a Rack constraint that validates the
  # Authorization: Bearer <token> header using the same JWT logic as the API.
  # Unauthenticated requests receive a 404 (no route match) from Rails.
  mount Sidekiq::Web => "/admin/sidekiq", constraints: SidekiqAuthConstraint.new

  # GraphQL endpoint
  post "/graphql", to: "graphql#execute"

  # GraphiQL playground (development only)
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  namespace :api do
    # Public health check endpoints — no authentication required
    get "health", to: "health#show"
    get "up",     to: "health#show"

    # Dev auth bypass — only available in development when DEV_AUTH_BYPASS=true.
    # Issues a signed token for local development without a real OIDC provider.
    if Rails.env.development?
      namespace :dev do
        post "auth", to: "auth#create"
      end
    end

    namespace :v1 do
      resources :characters

      resources :quests do
        resources :members, only: %i[create destroy], param: :character_id,
                  controller: "quests/members"
        resources :events, only: %i[index], controller: "quests/events"
      end

      resources :artifacts, except: %i[destroy]

      get  "simulation/status", to: "simulation#status"
      post "simulation/start",  to: "simulation#start"
      post "simulation/stop",   to: "simulation#stop"
      post "simulation/mode",   to: "simulation#mode"
      post "simulation/reset",  to: "simulation#reset"

      resources :events, only: %i[index]
      get "leaderboard", to: "leaderboard#index"
      post "palantir/send", to: "palantir#deliver"
    end
  end
end
