Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users,
    path: "api/v1/auth",
    path_names: { sign_in: "sign_in", sign_out: "sign_out", password: "password" },
    controllers: {
      sessions: "api/v1/auth/sessions",
      passwords: "api/v1/auth/passwords",
      registrations: "api/v1/auth/registrations"
    }

  devise_for :admin_users,
    path: "api/v1/admin/auth",
    path_names: { sign_in: "sign_in", sign_out: "sign_out", password: "password" },
    controllers: {
      sessions: "api/v1/admin/auth/sessions",
      passwords: "api/v1/admin/auth/passwords"
    }

  namespace :api do
    namespace :v1 do
      resource  :profile, only: [:show, :update]
      resource  :dashboard, only: [:show]
      resources :leaves
      resources :leave_balances, only: [:index]
      resources :public_holidays, only: [:index]
      resources :team_requests, only: [:index, :show, :update]
      resources :work_experiences
      resources :family_members
      resources :user_documents
      resources :trainings
      resources :equipment_assignments
      resource  :app_settings, only: [:show, :update]

      namespace :admin do
        resource  :dashboard, only: [:show]
        resources :agencies
        resources :branches
        resources :claim_types
        resources :companies
        resources :users do
          resources :work_experiences,       only: [:index, :show, :create, :update, :destroy]
          resources :supervisors,            only: [:index, :create, :update, :destroy], controller: "supervisors"
          resources :family_members,         only: [:index, :show, :create, :update, :destroy]
          resources :career_progresses,      only: [:index, :show, :create, :update, :destroy]
          resources :user_documents,         only: [:index, :show, :create, :update, :destroy]
          resources :trainings,              only: [:index, :show, :create, :update, :destroy]
          resources :equipment_assignments,  only: [:index, :show, :create, :update, :destroy]
          resource  :payroll,                only: [:show, :update]
          resources :claim_policies,         only: [:index, :update]
          resources :claim_balances,         only: [:index]
          resources :claim_applications,     only: [:index, :show, :create, :update, :destroy]
        end
        resources :departments
        resources :designations
        resources :leave_policies
        resources :leave_types
        resources :work_schedules
        resources :public_holidays
        resources :leave_applications
        resources :warning_letters, only: [:index, :show, :create, :update]
        resources :activity_logs, only: [:index]
      end
    end
  end
end
