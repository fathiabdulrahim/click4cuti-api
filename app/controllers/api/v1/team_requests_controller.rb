module Api
  module V1
    class TeamRequestsController < BaseController
      def index
        requests = policy_scope(LeaveApplication).pending
                                                 .includes(:user, :leave_type)
                                                 .order(created_at: :asc)
        render json: LeaveApplicationBlueprint.render(requests, view: :detail)
      end

      def update
        leave = LeaveApplication.find(params[:id])
        authorize leave, :approve?
        result = Leaves::ApprovalService.new(leave, current_user, approval_params).call
        log_activity("LEAVE_#{result.status.upcase}", result)
        render json: LeaveApplicationBlueprint.render(result, view: :detail)
      rescue Leaves::ApprovalService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def approval_params
        params.require(:leave).permit(:status, :reviewer_remarks)
      end
    end
  end
end
