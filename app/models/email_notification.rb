class EmailNotification < ApplicationRecord
  belongs_to :company, optional: true

  enum :delivery_status, { pending: "PENDING", sent: "SENT", failed: "FAILED" }

  validates :recipient_email, :subject, :body, :notification_type, presence: true
  validates :recipient_type, :recipient_id, presence: true

  scope :unsent, -> { where(delivery_status: "PENDING") }
end
