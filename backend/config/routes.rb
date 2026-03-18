# frozen_string_literal: true

Rails.application.routes.draw do
  # OpenAPI spec (JSON) and Scalar interactive docs
  get "/api/docs",      to: "api/docs#ui",   format: false
  get "/api/docs.json", to: "api/docs#spec",  format: false

  # rswag-api engine (serves swagger files from swagger/)
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    get "health", to: "health#show"

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
