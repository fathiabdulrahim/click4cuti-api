module Api
  module V1
    module Admin
      class LeaveTypesController < BaseController
        def index
          leave_types = policy_scope(LeaveType).order(:name)
          render json: LeaveTypeBlueprint.render(leave_types)
        end

        def show
          leave_type = policy_scope(LeaveType).find(params[:id])
          authorize leave_type
          render json: LeaveTypeBlueprint.render(leave_type)
        end

        def create
          authorize LeaveType
          leave_type = LeaveType.create!(leave_type_params)
          render json: LeaveTypeBlueprint.render(leave_type), status: :created
        end

        def update
          leave_type = policy_scope(LeaveType).find(params[:id])
          authorize leave_type
          leave_type.update!(leave_type_params)
          render json: LeaveTypeBlueprint.render(leave_type)
        end

        def destroy
          leave_type = policy_scope(LeaveType).find(params[:id])
          authorize leave_type
          leave_type.update!(is_active: false)
          render json: { message: "Leave type deactivated." }
        end

        private

        def leave_type_params
          params.require(:leave_type).permit(
            :leave_policy_id, :name, :category,
            :default_days_tier1, :default_days_tier2, :default_days_tier3,
            :max_consecutive_days, :requires_document, :allows_half_day,
            :allows_carry_forward, :max_carry_forward_days,
            :max_times_per_year, :shared_balance_with, :is_active
          )
        end
      end
    end
  end
end
