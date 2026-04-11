module Api
  module V1
    module Admin
      class DesignationsController < BaseController
        def index
          designations = policy_scope(Designation).order(:title)
          render json: DesignationBlueprint.render(designations)
        end

        def show
          designation = policy_scope(Designation).find(params[:id])
          authorize designation
          render json: DesignationBlueprint.render(designation)
        end

        def create
          authorize Designation
          designation = Designation.create!(designation_params)
          render json: DesignationBlueprint.render(designation), status: :created
        end

        def update
          designation = policy_scope(Designation).find(params[:id])
          authorize designation
          designation.update!(designation_params)
          render json: DesignationBlueprint.render(designation)
        end

        def destroy
          designation = policy_scope(Designation).find(params[:id])
          authorize designation
          designation.update!(is_active: false)
          render json: { message: "Designation deactivated." }
        end

        private

        def designation_params
          params.require(:designation).permit(:title, :is_manager, :is_active, :company_id)
        end
      end
    end
  end
end
