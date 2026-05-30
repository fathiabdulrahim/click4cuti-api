class LeaveMailer < ApplicationMailer
  def notification(recipient, application, event)
    @recipient = recipient
    @application = application
    @event = event

    mail(
      to: recipient.email,
      subject: email_subject
    )
  end

  def application_cancelled(application)
    @application = application
    @manager = application.user.manager

    return if @manager.nil?

    mail(
      to: @manager.email,
      subject: "Leave Cancelled — #{application.leave_type.name}"
    )
  end

  def admin_leave_notification(application, admin, event)
    @application = application
    @admin = admin
    @event = event

    mail(
      to: admin.email,
      subject: admin_email_subject(event)
    )
  end

  private

  def email_subject
    case @event
    when :applied
      "New Leave Application — #{@application.leave_type.name}"
    when :approved
      "Leave Approved — #{@application.leave_type.name}"
    when :rejected
      "Leave Rejected — #{@application.leave_type.name}"
    when :cancelled
      "Leave Cancelled — #{@application.leave_type.name}"
    else
      "Leave Application Update"
    end
  end

  def admin_email_subject(event)
    case event.to_s
    when "applied"
      "New Leave Application — #{@application.leave_type.name}"
    when "cancelled"
      "Leave Cancelled — #{@application.leave_type.name}"
    else
      "Leave Application Update"
    end
  end
end