module Leaves
  # Calculates leave duration from day details, excluding public holidays and rest days
  class DurationCalculator
    def initialize(user, start_date, end_date, day_details = nil)
      @user        = user
      @start_date  = start_date.to_date
      @end_date    = end_date.to_date
      @day_details = day_details
    end

    def calculate
      if @day_details.present?
        calculate_from_details
      else
        calculate_from_range
      end
    end

    private

    def calculate_from_details
      @day_details.sum do |detail|
        day_value(detail[:day_type].to_s)
      end
    end

    def calculate_from_range
      public_holiday_dates = PublicHoliday
        .where(company: @user.company)
        .for_date_range(@start_date, @end_date)
        .pluck(:holiday_date)
        .to_set

      work_schedule = current_work_schedule
      rest_days = work_schedule&.rest_days_array || ["Saturday", "Sunday"]

      total = 0.0
      current = @start_date
      while current <= @end_date
        day_name = current.strftime("%A")
        unless rest_days.include?(day_name) || public_holiday_dates.include?(current)
          total += 1.0
        end
        current += 1.day
      end
      total
    end

    def current_work_schedule
      uws = UserWorkSchedule.active_on(Date.current).find_by(user: @user)
      uws&.work_schedule
    end

    def day_value(day_type)
      case day_type
      when "FULL_DAY"    then 1.0
      when "HALF_DAY_AM" then 0.5
      when "HALF_DAY_PM" then 0.5
      else 1.0
      end
    end
  end
end
