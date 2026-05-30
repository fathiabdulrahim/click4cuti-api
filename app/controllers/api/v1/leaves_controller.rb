module Api
  module V1
    class LeavesController < BaseController
      def index
        leaves = policy_scope(LeaveApplication).order(created_at: :desc)
        render json: LeaveApplicationBlueprint.render(leaves)
      end

      def show
        leave = policy_scope(LeaveApplication).find(params[:id])
        authorize leave
        render json: LeaveApplicationBlueprint.render(leave, view: :detail)
      end

      def create
        authorize LeaveApplication
        result = Leaves::ApplyService.new(current_user, leave_params).call
        log_activity("LEAVE_APPLIED", result)
        render json: LeaveApplicationBlueprint.render(result, view: :detail), status: :created
      rescue Leaves::ApplyService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def update
        leave = policy_scope(LeaveApplication).find(params[:id])
        authorize leave
        result = Leaves::UpdateService.new(leave, current_user, leave_params).call
        log_activity("LEAVE_UPDATED", result)
        render json: LeaveApplicationBlueprint.render(result, view: :detail)
      rescue Leaves::UpdateService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        leave = LeaveApplication.find(params[:id])
        authorize leave
        result = Leaves::CancelService.new(leave, current_user).call
        log_activity("LEAVE_CANCELLED", result)
        render json: { message: "Leave application cancelled." }
      rescue Leaves::CancelService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def leave_params
        params.require(:leave).permit(
          :leave_type_id, :start_date, :end_date, :reason, :extended_reason, :document,
          leave_day_details_attributes: [:leave_date, :day_type]
        )
      end
    end
  end
end