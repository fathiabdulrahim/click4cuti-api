module Api
  module V1
    module Admin
      class CompaniesController < BaseController
        def index
          companies = policy_scope(Company).order(:name)
          render json: CompanyBlueprint.render(companies)
        end

        def show
          company = policy_scope(Company).find(params[:id])
          authorize company
          render json: CompanyBlueprint.render(company, view: :detail)
        end

        def create
          company = Company.new(company_params)
          authorize company
          Companies::OnboardService.new(company).call
          log_activity("COMPANY_CREATED", company)
          render json: CompanyBlueprint.render(company, view: :detail), status: :created
        end

        def update
          company = policy_scope(Company).find(params[:id])
          authorize company
          company.update!(company_params)
          log_activity("COMPANY_UPDATED", company)
          render json: CompanyBlueprint.render(company, view: :detail)
        end

        def destroy
          company = policy_scope(Company).find(params[:id])
          authorize company
          company.update!(is_active: false)
          log_activity("COMPANY_DEACTIVATED", company)
          render json: { message: "Company deactivated." }
        end

        private

        def company_params
          params.require(:company).permit(:name, :registration_number, :hr_email, :address, :state, :agency_id, :is_active)
        end
      end
    end
  end
end
