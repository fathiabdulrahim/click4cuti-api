class WarningLetterJob < ApplicationJob
  queue_as :default

  def perform(user_id, leave_type_id, year)
    user       = User.find(user_id)
    leave_type = LeaveType.find(leave_type_id)
    letter     = WarningLetter.where(user: user, leave_type: leave_type, year: year).last

    return unless letter

    WarningLetterMailer.issued(letter).deliver_now

    EmailNotification.create!(
      company_id:        user.company_id,
      recipient_email:   user.email,
      recipient_type:    "User",
      recipient_id:      user.id,
      subject:           "Warning Letter Issued — #{leave_type.name}",
      body:              letter.reason,
      notification_type: "WARNING_ISSUED",
      reference_id:      letter.id,
      reference_type:    "WarningLetter",
      delivery_status:   :sent,
      sent_at:           Time.current
    )
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "WarningLetterJob: #{e.message}"
  end
end
