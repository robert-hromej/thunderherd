# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    get "dashboard", to: "dashboard#index"
    resources :sites, only: %i[index show create update destroy]
    resources :environments, only: %i[index show create update destroy] do
      resources :urls, only: %i[index create update destroy], shallow: true
    end
    resources :run_configs, only: %i[index create update destroy]
    resources :operators, only: :index
    resources :machines, only: :index
    resources :app_deploys, only: :index
    resources :runs, only: %i[index show create update destroy] do
      get :compare, on: :member
    end
  end

  get "up", to: "rails/health#show", as: :rails_health_check

  # React (Vite) single-page app for everything else.
  root "app#index"
  get "*path", to: "app#index",
      constraints: ->(req) { !req.path.start_with?("/api", "/vite", "/assets", "/rails", "/up") }
end
