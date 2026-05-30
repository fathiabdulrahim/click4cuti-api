module Leaves
  class UpdateService
    Error = Class.new(StandardError)

    def initialize(leave, user, params)
      @leave  = leave
      @user   = user
      @params = params.to_h.with_indifferent_access
    end

    def call
      validate_pending!

      ActiveRecord::Base.transaction do
        old_leave_type = @leave.leave_type
        old_total_days = @leave.total_days

        leave_type = LeaveType.find(@params.fetch(:leave_type_id, @leave.leave_type_id))

        release_pending_balance!(old_leave_type, old_total_days)

        validate_leave_type!(leave_type)
        validate_advance_notice!(leave_type)
        validate_balance!(leave_type)
        validate_overlap!

        new_days = calculate_duration
        raise Error, "Selected dates contain no working days" if new_days <= 0

        requires_ceo = leave_type.max_consecutive_days.present? && new_days > leave_type.max_consecutive_days
        resolved_extended_reason = @params.fetch(:extended_reason, @leave.extended_reason)

        if requires_ceo && resolved_extended_reason.blank?
          raise Error, "Extended reason is required for leave exceeding #{leave_type.max_consecutive_days} consecutive days"
        end

        @leave.update!(
          leave_type:            leave_type,
          start_date:            @params.fetch(:start_date, @leave.start_date),
          end_date:              @params.fetch(:end_date, @leave.end_date),
          total_days:            new_days,
          reason:                @params.fetch(:reason, @leave.reason),
          extended_reason:       resolved_extended_reason,
          requires_ceo_approval: requires_ceo
        )

        rebuild_day_details!
        attach_document!

        hold_pending_balance!(leave_type, new_days)

        LeaveNotificationJob.perform_later(@leave.id, "updated")

        @leave
      end
    end

    private

    def validate_pending!
      unless @leave.pending?
        raise Error, "Only pending leave applications can be updated"
      end
    end

    def release_pending_balance!(leave_type, total_days)
      balance_type = leave_type.shared_balance_with.present? ? leave_type.shared_balance : leave_type
      balance = LeaveBalance.find_by(user: @user, leave_type: balance_type, year: @leave.start_date.year)
      return unless balance

      balance.update!(pending_days: [ balance.pending_days - total_days, 0 ].max)
      balance.recalculate_remaining!
    end

    def validate_leave_type!(leave_type)
      unless leave_type.active?
        raise Error, "Leave type is not available"
      end

      if leave_type.requires_document? && @params[:document].blank? && @leave.leave_documents.empty?
        raise Error, "A supporting document is required for #{leave_type.name}"
      end

      if leave_type.max_times_per_year.present?
        used_count = LeaveApplication.where(user: @user, leave_type: leave_type)
                                     .where.not(id: @leave.id)
                                     .where("EXTRACT(year FROM start_date) = ?", Date.current.year)
                                     .where(status: %w[PENDING APPROVED])
                                     .count
        if used_count >= leave_type.max_times_per_year
          raise Error, "You have reached the maximum #{leave_type.name} limit for this year"
        end
      end
    end

    def validate_advance_notice!(leave_type)
      notice_days = leave_type.leave_policy&.advance_notice_days.to_i
      return unless notice_days > 0

      start_date = Date.parse(@params.fetch(:start_date, @leave.start_date).to_s)
      min_start  = Date.current + notice_days.days

      if start_date < min_start
        raise Error, "#{leave_type.name} must be applied at least #{notice_days} day(s) in advance " \
                     "(earliest start date: #{min_start.strftime('%d %b %Y')})"
      end
    rescue Date::Error
      raise Error, "Invalid date format"
    end

    def validate_balance!(leave_type)
      balance_type = leave_type.shared_balance_with.present? ? leave_type.shared_balance : leave_type
      balance = LeaveBalance.find_by(user: @user, leave_type: balance_type, year: Date.current.year)
      return unless balance

      if balance.remaining_days <= 0
        raise Error, "Insufficient leave balance for #{leave_type.name}"
      end
    end

    def validate_overlap!
      start_date = Date.parse(@params.fetch(:start_date, @leave.start_date).to_s)
      end_date   = Date.parse(@params.fetch(:end_date, @leave.end_date).to_s)

      overlapping = LeaveApplication.where(user: @user)
                                    .where.not(id: @leave.id)
                                    .where(status: %w[PENDING APPROVED])
                                    .where("start_date <= ? AND end_date >= ?", end_date, start_date)

      if overlapping.exists?
        details = overlapping.map { |la| "#{la.start_date} to #{la.end_date} (#{la.status})" }
        raise Error, "You already have a leave application overlapping these dates: #{details.join(', ')}"
      end
    rescue Date::Error
      raise Error, "Invalid date format"
    end

    def calculate_duration
      start_date  = @params.fetch(:start_date, @leave.start_date)
      end_date    = @params.fetch(:end_date, @leave.end_date)
      day_details = @params[:leave_day_details_attributes]

      Leaves::DurationCalculator.new(@user, start_date, end_date, day_details).calculate
    end

    def rebuild_day_details!
      return unless @params[:leave_day_details_attributes].present?

      @leave.leave_day_details.destroy_all
      @params[:leave_day_details_attributes].each do |detail|
        @leave.leave_day_details.create!(
          leave_date: detail[:leave_date],
          day_type:   detail[:day_type]
        )
      end
    end

    def attach_document!
      doc = @params[:document]
      return if doc.blank?

      @leave.leave_documents.create!(
        file:         doc,
        file_name:    doc.original_filename,
        content_type: doc.content_type,
        file_size:    doc.size
      )
    end

    def hold_pending_balance!(leave_type, total_days)
      balance_type = leave_type.shared_balance_with.present? ? leave_type.shared_balance : leave_type
      balance = LeaveBalance.find_by(user: @user, leave_type: balance_type, year: Date.current.year)
      return unless balance

      balance.increment!(:pending_days, total_days)
      balance.recalculate_remaining!
    end
  end
end