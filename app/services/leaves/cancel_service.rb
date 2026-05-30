module Leaves
  class CancelService
    Error = Class.new(StandardError)

    def initialize(application, cancelled_by)
      @application  = application
      @cancelled_by = cancelled_by
    end

    def call
      validate_status!

      ApplicationRecord.transaction do
        case @application.status
        when "pending"
          @application.update!(status: :cancelled)
          release_pending_balance
        when "approved"
          @application.update!(status: :cancelled)
          release_used_balance
        else
          raise Error, "Cannot cancel a #{@application.status} leave application"
        end
      end

      LeaveNotificationJob.perform_later(@application.id, "cancelled")
      @application
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.message
    end

    private

    def validate_status!
      unless ["pending", "approved"].include?(@application.status)
        raise Error, "Cannot cancel a #{@application.status} leave application"
      end
    end

    def release_pending_balance
      balance = @application.user.leave_balances.find_by(
        leave_type_id: @application.leave_type_id,
        year: @application.start_date.year
      )
      return unless balance

      balance.update!(pending_days: [balance.pending_days - @application.total_days, 0].max)
    end

    def release_used_balance
      balance = @application.user.leave_balances.find_by(
        leave_type_id: @application.leave_type_id,
        year: @application.start_date.year
      )
      return unless balance

      balance.update!(used_days: [balance.used_days - @application.total_days, 0].max)
    end
  end
end