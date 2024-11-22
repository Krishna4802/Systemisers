Rails.application.routes.draw do
  # For DeviseTokenAuth
  devise_for :users, controllers: {
                       sessions: "users/sessions",
                       registrations: "users/registrations",
                       confirmations: "users/confirmations",
                       passwords: "users/passwords"
                     }

  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  devise_scope :user do
    post "users/validate_email", to: "users/sessions#validate_email"
  end

  post "gst_search", to: "gst_search#search"
  post 'incometaxfilesdownload', to: 'income_tax_files#download_files'

  namespace :api do
    namespace :v1 do # rubocop:disable Naming/VariableNumber
      namespace :master_data do
        resources :types_of_assets
        resources :company_type
        resources :category_of_customers
      end

      resources :user

      resources :project_report, only: %w[create update destroy show] do
        resources :loan_details, only: %w[create update destroy show]
        resources :od_cc_details, only: %w[create update destroy show]
        resources :new_loan_details, only: %w[create update destroy show]
      end
    end
    resources :company_documents
  end
end
