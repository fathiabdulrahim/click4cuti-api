module Api
  module V1
    module Admin
      class BranchesController < BaseController
        before_action :set_branch, only: [ :show, :update, :destroy ]

        def index
          records = policy_scope(Branch).order(:name)
          render json: BranchBlueprint.render(records)
        end

        def show
          authorize @branch
          render json: BranchBlueprint.render(@branch, view: :detail)
        end

        def create
          @branch = Branch.new(branch_params.merge(company_id: company_id_for_create))
          authorize @branch
          if @branch.save
            log_activity("branch.create", @branch)
            render json: BranchBlueprint.render(@branch), status: :created
          else
            render json: { errors: @branch.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          authorize @branch
          if @branch.update(branch_params)
            log_activity("branch.update", @branch)
            render json: BranchBlueprint.render(@branch)
          else
            render json: { errors: @branch.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @branch
          @branch.update!(is_active: false)
          log_activity("branch.deactivate", @branch)
          head :no_content
        end

        private

        def set_branch
          @branch = Branch.find(params[:id])
        end

        def branch_params
          params.require(:branch).permit(:name, :address, :state, :is_active)
        end

        def company_id_for_create
          params.dig(:branch, :company_id) || current_admin_user.company_id
        end
      end
    end
  end
end
