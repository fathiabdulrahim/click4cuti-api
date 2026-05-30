class TeamCoverageService
  def initialize(leave_application)
    @leave = leave_application
    @company_id = leave_application.user.company_id
    @start_date = leave_application.start_date
    @end_date = leave_application.end_date
  end

  def call
    preload_approved_leaves
    preload_public_holidays

    {
      leave_id:    @leave.id,
      start_date:  @start_date,
      end_date:    @end_date,
      applicant:   applicant_info,
      team_size:   team_size,
      days:        build_days
    }
  end

  private

  def preload_approved_leaves
    @approved_leaves = LeaveApplication.approved
                                       .for_company(@company_id)
                                       .where("start_date <= ? AND end_date >= ?", @end_date, @start_date)
                                       .includes(:user, :leave_type)
  end

  def preload_public_holidays
    @public_holidays = PublicHoliday.where(company_id: @company_id)
                                   .where(holiday_date: @start_date..@end_date)
                                   .pluck(:holiday_date)
                                   .to_set
  end

  def applicant_info
    user = @leave.user
    {
      id:         user.id,
      full_name:  user.full_name,
      department: user.department&.name
    }
  end

  def team_size
    User.where(company_id: @company_id, is_active: true).count
  end

  def build_days
    (@start_date..@end_date).map { |date| build_day(date) }
  end

  def build_day(date)
    day_leaves = @approved_leaves.select { |l| l.start_date <= date && l.end_date >= date }
    others = day_leaves.reject { |l| l.user_id == @leave.user_id }
                       .map { |l| { user_id: l.user_id, full_name: l.user.full_name, leave_type: l.leave_type.name } }
                       .uniq { |h| h[:user_id] }

    out_count = others.size + 1  # +1 for applicant

    {
      date:                date.to_s,
      day_of_week:         date.strftime("%A"),
      is_weekend:          date.saturday? || date.sunday?,
      is_public_holiday:   @public_holidays.include?(date),
      public_holiday_name: nil,
      team_size:           team_size,
      out_count:           out_count,
      present_count:       team_size - out_count,
      others_on_leave:     others
    }
  end
end