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

  # Sidekiq Web UI — development only; not exposed in production.
  # In production the route is not mounted at all, providing no attack surface.
  # The previous constraint-based approach failed with DEV_AUTH_BYPASS=true
  # because the constraint only understands OIDC JWTs, not dev bypass tokens.
  if Rails.env.development?
    mount Sidekiq::Web => "/admin/sidekiq"
  end

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

    # Dev auth bypass — issues a signed token for local development without a
    # real OIDC provider.  The route is always drawn so request specs can reach
    # it, but the controller enforces the runtime guard:
    #   Rails.env.development? && ENV["DEV_AUTH_BYPASS"] == "true"
    # Non-development requests receive a 404 from the controller.
    namespace :dev do
      post "auth", to: "auth#create"
    end

    namespace :v1 do
      resources :characters

      resources :quests do
        collection do
          post :reset
          post :randomize
        end
        resources :members, only: %i[create destroy], param: :character_id,
                  controller: "quests/members"
        resources :events, only: %i[index], controller: "quests/events"
      end

      resources :artifacts, except: %i[destroy]

      get   "simulation/status", to: "simulation#status"
      post  "simulation/start",  to: "simulation#start"
      post  "simulation/stop",   to: "simulation#stop"
      post  "simulation/mode",   to: "simulation#mode"
      patch "simulation/config", to: "simulation#config"
      post  "simulation/reset",  to: "simulation#reset"

      resources :events, only: %i[index]
      get "leaderboard", to: "leaderboard#index"
      post "palantir/send", to: "palantir#deliver"
    end
  end
end
