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
        params.permit(:full_name, :phone, :address)
      end
    end
  end
end
