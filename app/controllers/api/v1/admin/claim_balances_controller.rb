module Api
  module V1
    module Admin
      class ClaimBalancesController < BaseController
        before_action :set_user

        def index
          year = params[:year]&.to_i || Date.current.year
          records = policy_scope(ClaimBalance).where(user_id: @user.id, year: year)
          render json: ClaimBalanceBlueprint.render(records)
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end
      end
    end
  end
end
