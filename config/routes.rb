Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # NetSuite OAuth2 callback route
  get "netsuite/callback", to: "netsuite#callback"
  post "netsuite/sync_order", to: "netsuite#sync_order"
  post "netsuite/sync_estimate", to: "netsuite#sync_estimate"
  post "netsuite/sync_opportunity", to: "netsuite#sync_opportunity"
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  resource :hubspot, only: [] do
    post :callback
    post :create_contact_customer
    get :create_ns_quote
    get :create_duplicate_ns_quote
  end
end
