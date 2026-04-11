module Leaves
  class ApplyService
    Error = Class.new(StandardError)

    def initialize(user, params)
      @user   = user
      @params = params.to_h.with_indifferent_access
    end

    def call
      ActiveRecord::Base.transaction do
        leave_type = LeaveType.find(@params[:leave_type_id])

        validate_leave_type!(leave_type)
        validate_balance!(leave_type)

        application = build_application(leave_type)
        application.save!

        build_day_details(application)

        update_pending_balance!(application, leave_type)

        LeaveNotificationJob.perform_later(application.id, "applied")
        Leaves::WarningChecker.new(@user, leave_type).check!

        application
      end
    end

    private

    def validate_leave_type!(leave_type)
      unless leave_type.active?
        raise Error, "Leave type is not available"
      end

      if leave_type.requires_document? && @params[:document].blank?
        # Document validated at upload time — note for future enforcement
      end

      if leave_type.max_times_per_year.present?
        used_count = LeaveApplication.joins(:leave_type)
                                     .where(user: @user, leave_type: leave_type)
                                     .where("EXTRACT(year FROM start_date) = ?", Date.current.year)
                                     .where(status: %w[PENDING APPROVED])
                                     .count
        if used_count >= leave_type.max_times_per_year
          raise Error, "You have reached the maximum #{leave_type.name} limit for this year"
        end
      end
    end

    def validate_balance!(leave_type)
      balance_type = leave_type.shared_balance_with.present? ? leave_type.shared_balance : leave_type
      balance = LeaveBalance.find_by(user: @user, leave_type: balance_type, year: Date.current.year)
      return unless balance

      if balance.remaining_days <= 0
        raise Error, "Insufficient leave balance for #{leave_type.name}"
      end
    end

    def build_application(leave_type)
      days = Leaves::DurationCalculator.new(@user, @params[:start_date], @params[:end_date],
                                            @params[:leave_day_details_attributes]).calculate

      requires_ceo = leave_type.max_consecutive_days.present? && days > leave_type.max_consecutive_days

      @user.leave_applications.build(
        leave_type:           leave_type,
        start_date:           @params[:start_date],
        end_date:             @params[:end_date],
        total_days:           days,
        reason:               @params[:reason],
        extended_reason:      @params[:extended_reason],
        requires_ceo_approval: requires_ceo,
        status:               :pending
      )
    end

    def build_day_details(application)
      return unless @params[:leave_day_details_attributes].present?

      @params[:leave_day_details_attributes].each do |detail|
        application.leave_day_details.create!(
          leave_date: detail[:leave_date],
          day_type:   detail[:day_type]
        )
      end
    end

    def update_pending_balance!(application, leave_type)
      balance_type = leave_type.shared_balance_with.present? ? leave_type.shared_balance : leave_type
      balance = LeaveBalance.find_by(user: @user, leave_type: balance_type, year: Date.current.year)
      return unless balance

      balance.increment!(:pending_days, application.total_days)
      balance.recalculate_remaining!
    end
  end
end
