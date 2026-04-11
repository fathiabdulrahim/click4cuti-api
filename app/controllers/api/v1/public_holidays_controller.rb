module Api
  module V1
    class PublicHolidaysController < BaseController
      def index
        year = params[:year]&.to_i || Date.current.year
        holidays = policy_scope(PublicHoliday).for_year(year).order(:holiday_date)
        render json: PublicHolidayBlueprint.render(holidays)
      end
    end
  end
end
