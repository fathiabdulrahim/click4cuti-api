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
        leave = LeaveApplication.find(params[:id])
        authorize leave
        if leave.update(leave_params)
          render json: LeaveApplicationBlueprint.render(leave, view: :detail)
        else
          render json: { errors: leave.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        leave = LeaveApplication.find(params[:id])
        authorize leave
        leave.update!(status: :cancelled)
        log_activity("LEAVE_CANCELLED", leave)
        render json: { message: "Leave application cancelled." }
      end

      private

      def leave_params
        params.require(:leave).permit(
          :leave_type_id, :start_date, :end_date, :reason, :extended_reason,
          leave_day_details_attributes: [:leave_date, :day_type]
        )
      end
    end
  end
end
