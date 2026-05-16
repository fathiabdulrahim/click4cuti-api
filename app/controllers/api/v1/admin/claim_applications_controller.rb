module Api
  module V1
    module Admin
      class ClaimApplicationsController < BaseController
        before_action :set_user
        before_action :set_claim_application, only: [ :show, :update, :destroy ]

        def index
          records = policy_scope(ClaimApplication).where(user_id: @user.id).order(claim_date: :desc)
          render json: ClaimApplicationBlueprint.render(records)
        end

        def show
          authorize @claim_application
          render json: ClaimApplicationBlueprint.render(@claim_application, view: :detail)
        end

        def create
          @claim_application = @user.claim_applications.new(claim_application_params)
          authorize @claim_application
          if @claim_application.save
            log_activity("claim_application.create", @claim_application)
            render json: ClaimApplicationBlueprint.render(@claim_application), status: :created
          else
            render json: { errors: @claim_application.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          authorize @claim_application
          if @claim_application.update(claim_application_params)
            log_activity("claim_application.update", @claim_application)
            render json: ClaimApplicationBlueprint.render(@claim_application)
          else
            render json: { errors: @claim_application.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @claim_application
          @claim_application.destroy!
          log_activity("claim_application.destroy", @claim_application)
          head :no_content
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def set_claim_application
          @claim_application = ClaimApplication.find(params[:id])
        end

        def claim_application_params
          params.require(:claim_application).permit(
            :claim_type_id, :amount, :claim_date, :reason, :status, :reviewer_remarks
          )
        end
      end
    end
  end
end
