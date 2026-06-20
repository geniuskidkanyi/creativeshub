Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
  get "dashboard", to: "dashboard#show", as: :dashboard

  resource :account, only: [ :new, :create, :edit, :update ]

  resources :clients do
    collection do
      get :search
    end
  end
  resources :invoices do
    member do
      get :pay
      post :send_invoice
    end
  end

  namespace :public, path: "inv" do
    resources :invoices, only: [ :show ], param: :token, path: "" do
      member do
        get :pay
      end
    end
  end

  post "process_waychit_payment", to: "webhooks/waychit#receive"
end
