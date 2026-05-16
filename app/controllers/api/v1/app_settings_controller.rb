module Api
  module V1
    class AppSettingsController < BaseController
      skip_after_action :verify_policy_scoped

      def show
        authorize :app_setting, :show?
        render json: AppSettingBlueprint.render(current_user)
      end

      def update
        authorize :app_setting, :update?
        if current_user.update(app_setting_params)
          log_activity("app_setting.update", current_user)
          render json: AppSettingBlueprint.render(current_user)
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def app_setting_params
        params.permit(
          :notifications_enabled,
          :clock_in_selfie_enabled,
          :early_late_indicator_enabled,
          :attendance_confirmation_enabled
        )
      end
    end
  end
end
