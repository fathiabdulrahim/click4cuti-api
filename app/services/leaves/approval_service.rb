module Leaves
  class ApprovalService
    Error = Class.new(StandardError)

    def initialize(application, approver, params)
      @application = application
      @approver    = approver
      @params      = params.to_h.with_indifferent_access
    end

    def call
      raise Error, "Application is not pending" unless @application.pending? || @application.pending_ceo?

      new_status = @params[:status].to_s.upcase

      ActiveRecord::Base.transaction do
        if new_status == "APPROVED" && @application.requires_ceo_approval? && !ceo_approver?
          @application.update!(
            status:           :pending_ceo,
            approver:         @approver,
            reviewer_remarks: @params[:reviewer_remarks]
          )
          LeaveNotificationJob.perform_later(@application.id, @application.status)
        else
          @application.update!(
            status:           new_status.downcase,
            approver:         @approver,
            reviewer_remarks: @params[:reviewer_remarks]
          )

          if @application.approved?
            move_balance_from_pending_to_used!
          elsif @application.rejected?
            release_pending_balance!
          end

          LeaveNotificationJob.perform_later(@application.id, @application.status)
        end
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

    def ceo_approver?
      @approver.respond_to?(:company?) && @approver.company?
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
