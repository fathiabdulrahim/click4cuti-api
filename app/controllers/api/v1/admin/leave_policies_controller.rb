module Api
  module V1
    module Admin
      class LeavePoliciesController < BaseController
        def index
          policies = policy_scope(LeavePolicy).includes(:leave_types).order(:name)
          render json: LeavePolicyBlueprint.render(policies)
        end

        def show
          leave_policy = policy_scope(LeavePolicy).find(params[:id])
          authorize leave_policy
          render json: LeavePolicyBlueprint.render(leave_policy, view: :detail)
        end

        def create
          authorize LeavePolicy
          leave_policy = LeavePolicy.create!(leave_policy_params)
          log_activity("LEAVE_POLICY_CREATED", leave_policy)
          render json: LeavePolicyBlueprint.render(leave_policy, view: :detail), status: :created
        end

        def update
          leave_policy = policy_scope(LeavePolicy).find(params[:id])
          authorize leave_policy
          leave_policy.update!(leave_policy_params)
          render json: LeavePolicyBlueprint.render(leave_policy, view: :detail)
        end

        def destroy
          leave_policy = policy_scope(LeavePolicy).find(params[:id])
          authorize leave_policy
          leave_policy.update!(is_active: false)
          render json: { message: "Leave policy deactivated." }
        end

        private

        def leave_policy_params
          params.require(:leave_policy).permit(:name, :description, :advance_notice_days, :is_active, :company_id)
        end
      end
    end
  end
end
