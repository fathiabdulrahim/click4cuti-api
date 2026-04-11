module Api
  module V1
    module Admin
      class AgenciesController < BaseController
        def index
          agencies = policy_scope(HrAgency).order(:name)
          render json: AgencyBlueprint.render(agencies)
        end

        def show
          agency = HrAgency.find(params[:id])
          authorize agency
          render json: AgencyBlueprint.render(agency, view: :detail)
        end

        def create
          agency = HrAgency.new(agency_params)
          authorize agency
          agency.save!
          log_activity("AGENCY_CREATED", agency)
          render json: AgencyBlueprint.render(agency, view: :detail), status: :created
        end

        def update
          agency = HrAgency.find(params[:id])
          authorize agency
          agency.update!(agency_params)
          log_activity("AGENCY_UPDATED", agency)
          render json: AgencyBlueprint.render(agency, view: :detail)
        end

        def destroy
          agency = HrAgency.find(params[:id])
          authorize agency
          agency.update!(is_active: false)
          log_activity("AGENCY_DEACTIVATED", agency)
          render json: { message: "Agency deactivated." }
        end

        private

        def agency_params
          params.require(:agency).permit(:name, :email, :phone, :address, :is_active)
        end
      end
    end
  end
end
