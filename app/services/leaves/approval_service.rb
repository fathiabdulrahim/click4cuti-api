module Leaves
  class ApprovalService
    Error = Class.new(StandardError)

    def initialize(application, approver, params)
      @application = application
      @approver    = approver
      @params      = params.to_h.with_indifferent_access
    end

    def call
      raise Error, "Application is not pending" unless @application.pending?

      new_status = @params[:status].to_s.upcase

      ActiveRecord::Base.transaction do
        @application.update!(
          status:           new_status.downcase,
          approved_by:      @approver.is_a?(User) ? @approver.id : nil,
          reviewer_remarks: @params[:reviewer_remarks]
        )

        if @application.approved?
          move_balance_from_pending_to_used!
        elsif @application.rejected?
          release_pending_balance!
        end

        LeaveNotificationJob.perform_later(@application.id, @application.status)
      end

      @application
    end

    private

    def move_balance_from_pending_to_used!
      balance = find_balance
      return unless balance

      balance.decrement!(:pending_days, @application.total_days)
      balance.increment!(:used_days, @application.total_days)
      balance.recalculate_remaining!
    end

    def release_pending_balance!
      balance = find_balance
      return unless balance

      balance.decrement!(:pending_days, @application.total_days)
      balance.recalculate_remaining!
    end

    def find_balance
      leave_type = @application.leave_type
      balance_type = leave_type.shared_balance_with.present? ? leave_type.shared_balance : leave_type
      LeaveBalance.find_by(
        user:       @application.user,
        leave_type: balance_type,
        year:       @application.start_date.year
      )
    end
  end
end
