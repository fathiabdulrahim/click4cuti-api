module Api
  module V1
    class DashboardsController < BaseController
      skip_after_action :verify_policy_scoped

      def show
        authorize :dashboard, :show?
        stats = Dashboard::StatsService.new(current_user).call
        render json: stats
      end
    end
  end
end
