module Dashboard
  class AdminStatsService
    def initialize(admin_user)
      @admin  = admin_user
      @year   = Date.current.year
    end

    def call
      {
        total_employees:      employee_count,
        pending_approvals:    pending_count,
        on_leave_today:       on_leave_today_count,
        approved_ytd:         approved_ytd,
        rejected_ytd:         rejected_ytd,
        leave_by_type:        leave_by_type,
        recent_applications:  recent_applications
      }
    end

    private

    def base_scope
      case @admin.scope
      when "SUPER_ADMIN" then LeaveApplication.all
      when "AGENCY"
        LeaveApplication.joins(user: :company).where(companies: { agency_id: @admin.agency_id })
      when "COMPANY"
        LeaveApplication.joins(:user).where(users: { company_id: @admin.company_id })
      end
    end

    def user_scope
      case @admin.scope
      when "SUPER_ADMIN" then User.all
      when "AGENCY"      then User.joins(:company).where(companies: { agency_id: @admin.agency_id })
      when "COMPANY"     then User.where(company_id: @admin.company_id)
      end
    end

    def employee_count
      user_scope.active.count
    end

    def pending_count
      base_scope.pending.count
    end

    def on_leave_today_count
      today = Date.current
      base_scope.approved
                .where("start_date <= ? AND end_date >= ?", today, today)
                .count
    end

    def approved_ytd
      base_scope.approved
                .where("EXTRACT(year FROM start_date) = ?", @year)
                .count
    end

    def rejected_ytd
      base_scope.rejected
                .where("EXTRACT(year FROM start_date) = ?", @year)
                .count
    end

    def leave_by_type
      base_scope.approved
                .where("EXTRACT(year FROM start_date) = ?", @year)
                .joins(:leave_type)
                .group("leave_types.name")
                .count
    end

    def recent_applications
      base_scope.includes(:user, :leave_type)
                .order(created_at: :desc)
                .limit(10)
                .map do |la|
        {
          id:           la.id,
          user:         la.user.full_name,
          leave_type:   la.leave_type.name,
          status:       la.status,
          start_date:   la.start_date,
          total_days:   la.total_days
        }
      end
    end
  end
end
