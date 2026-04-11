module Api
  module V1
    module Admin
      class LeaveApplicationsController < BaseController
        def index
          applications = policy_scope(LeaveApplication)
                           .includes(:user, :leave_type, :approver)
                           .order(created_at: :desc)
          applications = applications.where(status: params[:status]) if params[:status].present?
          render json: LeaveApplicationBlueprint.render(applications, view: :detail)
        end

        def show
          application = policy_scope(LeaveApplication).find(params[:id])
          authorize application
          render json: LeaveApplicationBlueprint.render(application, view: :detail)
        end

        def create
          authorize LeaveApplication
          application = LeaveApplication.create!(application_params)
          render json: LeaveApplicationBlueprint.render(application, view: :detail), status: :created
        end

        def update
          application = policy_scope(LeaveApplication).find(params[:id])
          authorize application
          result = Leaves::ApprovalService.new(application, current_admin_user, update_params).call
          log_activity("LEAVE_#{result.status.upcase}", result)
          render json: LeaveApplicationBlueprint.render(result, view: :detail)
        end

        def destroy
          application = policy_scope(LeaveApplication).find(params[:id])
          authorize application
          application.update!(status: :cancelled)
          render json: { message: "Application cancelled." }
        end

        private

        def application_params
          params.require(:leave_application).permit(
            :user_id, :leave_type_id, :start_date, :end_date, :reason,
            :extended_reason, :status, :requires_ceo_approval
          )
        end

        def update_params
          params.require(:leave_application).permit(:status, :reviewer_remarks)
        end
      end
    end
  end
end
