Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :game, only: %i[new] do
    collection do
      post :next_generation  # Keep this for fallback/initial load
      post :resize
      post "/new", to: "game#create"
    end
  end

  devise_for :users

  mount ActionCable.server => "/cable"

  # Defines the root path route ("/")
  root "game#new"
end
