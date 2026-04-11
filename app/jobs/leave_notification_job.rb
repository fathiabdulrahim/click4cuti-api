class LeaveNotificationJob < ApplicationJob
  queue_as :default

  def perform(application_id, event)
    application = LeaveApplication.includes(:user, :leave_type, :approver).find(application_id)

    case event
    when "applied"
      LeaveMailer.application_submitted(application).deliver_now
      LeaveMailer.manager_notification(application).deliver_now if application.user.manager.present?
    when "approved"
      LeaveMailer.application_approved(application).deliver_now
    when "rejected"
      LeaveMailer.application_rejected(application).deliver_now
    end

    EmailNotification.create!(
      company_id:        application.user.company_id,
      recipient_email:   application.user.email,
      recipient_type:    "User",
      recipient_id:      application.user.id,
      subject:           email_subject(event, application),
      body:              "Leave #{event} for #{application.leave_type.name}",
      notification_type: "LEAVE_#{event.upcase}",
      reference_id:      application.id,
      reference_type:    "LeaveApplication",
      delivery_status:   :sent,
      sent_at:           Time.current
    )
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "LeaveNotificationJob: application #{application_id} not found"
  end

  private

  def email_subject(event, application)
    case event
    when "applied"   then "Leave Application Submitted — #{application.leave_type.name}"
    when "approved"  then "Leave Application Approved — #{application.leave_type.name}"
    when "rejected"  then "Leave Application Rejected — #{application.leave_type.name}"
    else "Leave Application Update"
    end
  end
end
