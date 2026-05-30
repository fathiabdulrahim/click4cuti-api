Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication
      devise_for :users, controllers: {
        registrations: "api/v1/auth/registrations",
        sessions: "api/v1/auth/sessions"
      }

      # Profile
      get "profile", to: "profile#show"

      # Leave types
      resources :leave_types, only: [:index]

      # Leave applications (employee-facing)
      resources :leaves, only: [:index, :show, :create, :destroy] do
        member do
          post :cancel
        end
      end

      # Leave balances
      get "leave_balances", to: "leave_balances#index"

      # Team requests (manager approving subordinates)
      resources :team_requests, only: [:index, :show, :update]

      # Public holidays
      resources :public_holidays, only: [:index]

      # Dashboard
      get "dashboard", to: "dashboard#index"

      # Work schedules
      resources :work_schedules, only: [:index]

      # User documents
      resources :user_documents, only: [:index, :show, :create, :destroy]

      # Trainings
      resources :trainings, only: [:index, :show]

      # Equipment
      resources :equipment, only: [:index, :show]

      # Admin namespace
      namespace :admin do
        # Admin authentication
        devise_for :admin_users, controllers: {
          sessions: "api/v1/admin/auth/sessions"
        }

        # Dashboard
        get "dashboard", to: "dashboard#index"

        # Users management
        resources :users, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :reset_password
          end
        end

        # Leave applications management
        resources :leave_applications, only: [:index, :show, :update, :destroy]

        # Leave types management
        resources :leave_types, only: [:index, :show, :create, :update, :destroy]

        # Leave balances management
        resources :leave_balances, only: [:index, :show]

        # Public holidays management
        resources :public_holidays, only: [:index, :show, :create, :update, :destroy]

        # Companies management (super_admin only)
        resources :companies, only: [:index, :show, :create, :update]

        # User documents
        resources :user_documents, only: [:index, :show, :update, :destroy]

        # Trainings
        resources :trainings, only: [:index, :show, :create, :update, :destroy]

        # Equipment
        resources :equipment, only: [:index, :show, :create, :update, :destroy]

        # Warnings
        resources :warnings, only: [:index, :show]

        # Reports
        get "reports/leave_summary", to: "reports#leave_summary"
      end
    end
  end
end
