module Dashboard
  class StatsService
    def initialize(user)
      @user = user
      @year = Date.current.year
    end

    def call
      {
        leave_balances:      leave_balances,
        pending_requests:    pending_count,
        approved_this_year:  approved_count,
        upcoming_holidays:   upcoming_holidays,
        recent_applications: recent_applications
      }
    end

    private

    def leave_balances
      LeaveBalance.where(user: @user, year: @year)
                  .includes(:leave_type)
                  .map do |b|
        {
          leave_type:    b.leave_type.name,
          total:         b.total_entitled,
          used:          b.used_days,
          pending:       b.pending_days,
          remaining:     b.remaining_days,
          carried_forward: b.carried_forward
        }
      end
    end

    def pending_count
      LeaveApplication.where(user: @user, status: :pending).count
    end

    def approved_count
      LeaveApplication.where(user: @user, status: :approved)
                      .where("EXTRACT(year FROM start_date) = ?", @year)
                      .count
    end

    def upcoming_holidays
      PublicHoliday.where(company: @user.company)
                   .where(holiday_date: Date.current..)
                   .where(year: @year)
                   .order(:holiday_date)
                   .limit(5)
                   .map { |ph| { name: ph.name, date: ph.holiday_date } }
    end

    def recent_applications
      LeaveApplication.where(user: @user)
                      .includes(:leave_type)
                      .order(created_at: :desc)
                      .limit(5)
                      .map do |la|
        {
          id:         la.id,
          leave_type: la.leave_type.name,
          status:     la.status,
          start_date: la.start_date,
          end_date:   la.end_date,
          total_days: la.total_days
        }
      end
    end
  end
end
