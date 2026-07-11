Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations", sessions: "users/sessions" }

  get "up" => "rails/health#show", as: :rails_health_check

  authenticated :user do
    root "dashboard#show", as: :authenticated_root
  end

  root "landing#show"
  get "dashboard", to: "dashboard#show", as: :dashboard

  resource :account, only: [ :new, :create, :edit, :update ]

  resources :clients do
    collection do
      get :search
    end
  end
  resources :products do
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

  resources :payouts, only: [ :index, :new, :create ]
  resources :payments, only: [ :show ]

  resource :qr_code, only: [ :show ], path: "qr"

  get "scan/:token", to: "public/qr_payments#show", as: :qr_scan
  post "scan/:token", to: "public/qr_payments#create", as: :qr_pay
  get "scan/:token/complete", to: "public/qr_payments#complete", as: :qr_complete

  namespace :public, path: "inv" do
    resources :invoices, only: [ :show ], param: :token, path: "" do
      member do
        get :pay
      end
    end
  end

  post "process_payment", to: "webhooks/modem_pay#receive"

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
