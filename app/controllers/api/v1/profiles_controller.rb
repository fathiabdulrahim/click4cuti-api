module Api
  module V1
    class ProfilesController < BaseController
      skip_after_action :verify_policy_scoped

      def show
        authorize :profile, :show?
        render json: UserBlueprint.render(current_user, view: :detail)
      end

      def update
        authorize :profile, :update?
        if current_user.update(profile_params)
          render json: UserBlueprint.render(current_user, view: :detail)
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.permit(
          :full_name, :first_name, :last_name, :phone, :address,
          :nric, :nric_old, :nric_color, :date_of_birth, :place_of_birth,
          :race, :religion, :blood_type, :education_level,
          :marital_status, :nationality, :bumi_status,
          :driving_license_number, :driving_license_class, :driving_license_expiry,
          :expo_push_token
        )
      end
    end
  end
end