module Api
  module V1
    module Admin
      class ClaimPoliciesController < BaseController
        before_action :set_user
        before_action :set_policy, only: [ :update ]

        # Returns one row per claim_type for this user. Creates default rows if missing.
        def index
          claim_types = policy_scope(ClaimType).where(company_id: @user.company_id, is_active: true)
          rows = claim_types.map do |ct|
            UserClaimPolicy.find_or_create_by!(user_id: @user.id, claim_type_id: ct.id) do |p|
              p.application_limit = ct.default_application_limit
              p.annual_limit      = ct.default_annual_limit
              p.is_included       = true
            end
          end
          render json: UserClaimPolicyBlueprint.render(rows)
        end

        def update
          authorize @policy
          if @policy.update(policy_params)
            log_activity("user_claim_policy.update", @policy)
            render json: UserClaimPolicyBlueprint.render(@policy)
          else
            render json: { errors: @policy.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def set_policy
          @policy = UserClaimPolicy.where(user_id: @user.id).find(params[:id])
        end

        def policy_params
          params.require(:user_claim_policy).permit(
            :application_limit, :annual_limit,
            :is_unlimited_application, :is_unlimited_annual,
            :is_included, :remarks
          )
        end
      end
    end
  end
end
