module Api
  module V1
    module Admin
      class DepartmentsController < BaseController
        def index
          departments = policy_scope(Department).order(:name)
          render json: DepartmentBlueprint.render(departments)
        end

        def show
          department = policy_scope(Department).find(params[:id])
          authorize department
          render json: DepartmentBlueprint.render(department)
        end

        def create
          authorize Department
          department = Department.create!(department_params)
          log_activity("DEPARTMENT_CREATED", department)
          render json: DepartmentBlueprint.render(department), status: :created
        end

        def update
          department = policy_scope(Department).find(params[:id])
          authorize department
          department.update!(department_params)
          render json: DepartmentBlueprint.render(department)
        end

        def destroy
          department = policy_scope(Department).find(params[:id])
          authorize department
          department.update!(is_active: false)
          render json: { message: "Department deactivated." }
        end

        private

        def department_params
          params.require(:department).permit(:name, :is_active, :company_id)
        end
      end
    end
  end
end
