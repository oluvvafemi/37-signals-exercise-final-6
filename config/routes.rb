Rails.application.routes.draw do
  resources :web_pages, only: [ :index ]
  get "up" => "rails/health#show", as: :rails_health_check

  root "web_pages#index"
  resources :mockups if Rails.env.development?
end
