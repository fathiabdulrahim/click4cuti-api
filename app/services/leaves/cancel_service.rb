module Leaves
  class CancelService
    Error = Class.new(StandardError)

    def initialize(application, cancelled_by)
      @application  = application
      @cancelled_by = cancelled_by
    end

    def call
      unless @application.pending? || @application.approved?
        raise Error, "Only pending or approved applications can be cancelled"
      end

      ActiveRecord::Base.transaction do
        was_approved = @application.approved?
        @application.update!(status: :cancelled)

        if was_approved
          release_used_balance!
        else
          release_pending_balance!
        end
      end

      @application
    end

    private

    def release_pending_balance!
      balance = find_balance
      return unless balance

      balance.decrement!(:pending_days, @application.total_days)
      balance.recalculate_remaining!
    end

    def release_used_balance!
      balance = find_balance
      return unless balance

      balance.decrement!(:used_days, @application.total_days)
      balance.recalculate_remaining!
    end

    def find_balance
      leave_type   = @application.leave_type
      balance_type = leave_type.shared_balance_with.present? ? leave_type.shared_balance : leave_type
      LeaveBalance.find_by(
        user:       @application.user,
        leave_type: balance_type,
        year:       @application.start_date.year
      )
    end
  end
end
