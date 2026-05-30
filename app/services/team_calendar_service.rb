class TeamCalendarService
  def initialize(company_id:, from_date:, to_date:)
    @company_id = company_id
    @from_date  = from_date
    @to_date    = to_date
    @today      = Date.current
  end

  def call
    {
      today_summary:    today_summary,
      upcoming_entries: upcoming_entries
    }
  end

  private

  def leaves_overlapping(from, to)
    LeaveApplication.approved
                    .for_company(@company_id)
                    .includes(:user, :leave_type)
                    .where("start_date <= ? AND end_date >= ?", to, from)
  end

  def today_summary
    leaves_today = leaves_overlapping(@today, @today)
    team_size    = User.where(company_id: @company_id, is_active: true).count

    {
      employees_out_count: leaves_today.map(&:user_id).uniq.size,
      total_team_size:     team_size,
      employees_out:       leaves_today.map { |la|
        { name: la.user.full_name, leave_type: la.leave_type.name }
      }
    }
  end

  def upcoming_entries
    leaves_overlapping(@from_date, @to_date).map { |la|
      {
        user_name:  la.user.full_name,
        leave_type: la.leave_type.name,
        start_date: la.start_date,
        end_date:   la.end_date,
        total_days: la.total_days
      }
    }
  end
end