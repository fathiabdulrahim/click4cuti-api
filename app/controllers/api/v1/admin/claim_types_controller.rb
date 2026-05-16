module Api
  module V1
    module Admin
      class ClaimTypesController < BaseController
        before_action :set_claim_type, only: [ :show, :update, :destroy ]

        def index
          records = policy_scope(ClaimType).order(:name)
          render json: ClaimTypeBlueprint.render(records)
        end

        def show
          authorize @claim_type
          render json: ClaimTypeBlueprint.render(@claim_type, view: :detail)
        end

        def create
          @claim_type = ClaimType.new(claim_type_params.merge(company_id: company_id_for_create))
          authorize @claim_type
          if @claim_type.save
            log_activity("claim_type.create", @claim_type)
            render json: ClaimTypeBlueprint.render(@claim_type), status: :created
          else
            render json: { errors: @claim_type.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          authorize @claim_type
          if @claim_type.update(claim_type_params)
            log_activity("claim_type.update", @claim_type)
            render json: ClaimTypeBlueprint.render(@claim_type)
          else
            render json: { errors: @claim_type.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @claim_type
          @claim_type.update!(is_active: false)
          log_activity("claim_type.deactivate", @claim_type)
          head :no_content
        end

        private

        def set_claim_type
          @claim_type = ClaimType.find(params[:id])
        end

        def claim_type_params
          params.require(:claim_type).permit(
            :name, :code, :description,
            :default_application_limit, :default_annual_limit,
            :requires_document, :is_active
          )
        end

        def company_id_for_create
          params.dig(:claim_type, :company_id) || current_admin_user.company_id
        end
      end
    end
  end
end
