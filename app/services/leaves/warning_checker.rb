module Leaves
  class WarningChecker
    EMERGENCY_LEAVE_THRESHOLD = 3

    def initialize(user, leave_type)
      @user       = user
      @leave_type = leave_type
    end

    def check!
      return unless emergency_leave?

      count = el_count_this_year
      return unless count > EMERGENCY_LEAVE_THRESHOLD

      create_warning_letter!(count)
      WarningLetterJob.perform_later(@user.id, @leave_type.id, Date.current.year)
    end

    private

    def emergency_leave?
      @leave_type.name.downcase.include?("emergency")
    end

    def el_count_this_year
      LeaveApplication
        .where(user: @user, leave_type: @leave_type)
        .where("EXTRACT(year FROM start_date) = ?", Date.current.year)
        .where(status: %w[PENDING APPROVED])
        .count
    end

    def create_warning_letter!(count)
      WarningLetter.create!(
        user:          @user,
        company:       @user.company,
        leave_type:    @leave_type,
        reason:        "Exceeded #{EMERGENCY_LEAVE_THRESHOLD} emergency leaves in #{Date.current.year}. Current count: #{count}",
        year:          Date.current.year,
        issued_date:   Date.current,
        acknowledged:  false
      )
    end
  end
end
