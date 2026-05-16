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
          assign_leave_approvers!(user)
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
            :full_name, :first_name, :last_name, :email, :phone, :mobile_phone,
            :personal_email, :address, :mailing_address,
            :emergency_contact_name, :emergency_contact_phone,
            :password, :role, :join_date, :gender, :number_of_children, :is_confirmed,
            :department_id, :designation_id, :manager_id, :employee_id, :branch_id,
            :company_id, :leave_policy_id, :work_schedule_id,
            :nric, :nric_old, :nric_color, :date_of_birth, :place_of_birth,
            :race, :religion, :blood_type, :education_level,
            :marital_status, :nationality, :bumi_status,
            :driving_license_number, :driving_license_class, :driving_license_expiry,
            :date_of_sign, :employee_type, :probation_period_days, :oku_status,
            :ea_person_in_charge_id,
            leave_approver_ids: []
          )
        end

        def user_update_params
          params.require(:user).permit(
            :full_name, :first_name, :last_name, :phone, :mobile_phone,
            :personal_email, :address, :mailing_address,
            :emergency_contact_name, :emergency_contact_phone,
            :role, :is_active, :is_confirmed,
            :department_id, :designation_id, :manager_id, :number_of_children,
            :branch_id,
            :nric, :nric_old, :nric_color, :date_of_birth, :place_of_birth,
            :race, :religion, :blood_type, :education_level,
            :marital_status, :nationality, :bumi_status,
            :driving_license_number, :driving_license_class, :driving_license_expiry,
            :date_of_sign, :employee_type, :probation_period_days, :oku_status,
            :ea_person_in_charge_id
          )
        end

        def assign_leave_approvers!(user)
          return unless params.dig(:user, :leave_approver_ids).is_a?(Array)
          ids = params[:user][:leave_approver_ids].compact
          if ids.any?
            same_company = User.where(id: ids, company_id: user.company_id).pluck(:id)
            unknown = ids.map(&:to_s) - same_company.map(&:to_s)
            raise ActiveRecord::RecordInvalid.new(user) if unknown.any?
          end
          user.leave_approver_ids = ids
        end
      end
    end
  end
end
