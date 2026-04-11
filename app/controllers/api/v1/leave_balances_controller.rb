module Api
  module V1
    class LeaveBalancesController < BaseController
      def index
        year = params[:year]&.to_i || Date.current.year
        balances = policy_scope(LeaveBalance).where(year: year)
                                             .includes(:leave_type)
                                             .order(:leave_type_id)
        render json: LeaveBalanceBlueprint.render(balances)
      end
    end
  end
end
