module Api
  module V1
    class TeamCalendarController < BaseController
      skip_after_action :verify_policy_scoped

      def index
        authorize :team_calendar, :index?
        from_date = parse_date(params[:from]) || Date.current
        to_date   = parse_date(params[:to])   || Date.current + 30.days

        result = TeamCalendarService.new(
          company_id: current_user.company_id,
          from_date:  from_date,
          to_date:    to_date
        ).call

        render json: result
      end

      private

      def parse_date(value)
        Date.parse(value.to_s) if value.present?
      rescue Date::Error
        nil
      end
    end
  end
end