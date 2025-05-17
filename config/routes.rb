Rails.application.routes.draw do
  resources :analyses, only: %i[ create show ]
  get "up" => "rails/health#show", as: :rails_health_check

  root "web_pages#index"
  resources :mockups if Rails.env.development?
end
