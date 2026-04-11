module Api
  module V1
    module Admin
      class DashboardsController < BaseController
        skip_after_action :verify_policy_scoped

        def show
          authorize :admin_dashboard, :show?
          stats = Dashboard::AdminStatsService.new(current_admin_user).call
          render json: stats
        end
      end
    end
  end
end
