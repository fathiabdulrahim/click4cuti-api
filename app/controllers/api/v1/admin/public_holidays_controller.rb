module Api
  module V1
    module Admin
      class PublicHolidaysController < BaseController
        def index
          year = params[:year]&.to_i || Date.current.year
          holidays = policy_scope(PublicHoliday).for_year(year).order(:holiday_date)
          render json: PublicHolidayBlueprint.render(holidays)
        end

        def show
          holiday = policy_scope(PublicHoliday).find(params[:id])
          authorize holiday
          render json: PublicHolidayBlueprint.render(holiday)
        end

        def create
          authorize PublicHoliday
          holiday = PublicHoliday.create!(holiday_params)
          render json: PublicHolidayBlueprint.render(holiday), status: :created
        end

        def update
          holiday = policy_scope(PublicHoliday).find(params[:id])
          authorize holiday
          holiday.update!(holiday_params)
          render json: PublicHolidayBlueprint.render(holiday)
        end

        def destroy
          holiday = policy_scope(PublicHoliday).find(params[:id])
          authorize holiday
          holiday.destroy!
          render json: { message: "Public holiday removed." }
        end

        private

        def holiday_params
          params.require(:public_holiday).permit(:name, :holiday_date, :year, :is_mandatory, :is_replacement, :company_id)
        end
      end
    end
  end
end
