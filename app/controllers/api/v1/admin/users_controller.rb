module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          users = policy_scope(User).includes(:department, :designation).order(:full_name)
          render json: UserBlueprint.render(users)
        end

        def show
          user = policy_scope(User).find(params[:id])
          authorize user
          render json: UserBlueprint.render(user, view: :detail)
        end

        def create
          authorize User
          user = Users::OnboardService.new(user_params, current_admin_user).call
          log_activity("USER_CREATED", user)
          render json: UserBlueprint.render(user, view: :detail), status: :created
        rescue Users::OnboardService::Error => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def update
          user = policy_scope(User).find(params[:id])
          authorize user
          user.update!(user_update_params)
          log_activity("USER_UPDATED", user)
          render json: UserBlueprint.render(user, view: :detail)
        end

        def destroy
          user = policy_scope(User).find(params[:id])
          authorize user
          user.update!(is_active: false)
          log_activity("USER_DEACTIVATED", user)
          render json: { message: "User deactivated." }
        end

        private

        def user_params
          params.require(:user).permit(
            :full_name, :email, :phone, :address, :password, :role,
            :join_date, :gender, :number_of_children, :is_confirmed,
            :department_id, :designation_id, :manager_id, :employee_id,
            :company_id, :leave_policy_id, :work_schedule_id
          )
        end

        def user_update_params
          params.require(:user).permit(
            :full_name, :phone, :address, :role, :is_active, :is_confirmed,
            :department_id, :designation_id, :manager_id, :number_of_children
          )
        end
      end
    end
  end
end
