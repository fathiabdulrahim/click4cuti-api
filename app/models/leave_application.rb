class LeaveApplication < ApplicationRecord
  belongs_to :user
  belongs_to :leave_type
  belongs_to :approver, class_name: "User", foreign_key: :approved_by, optional: true

  has_many :leave_day_details, dependent: :destroy
  has_many :leave_documents,   dependent: :destroy

  has_one_attached :document

  enum :status, {
    pending:   "PENDING",
    approved:  "APPROVED",
    rejected:  "REJECTED",
    cancelled: "CANCELLED"
  }

  validates :start_date, :end_date, :reason, presence: true
  validates :user, :leave_type, presence: true
  validate  :end_date_after_start_date
  validate  :extended_reason_if_ceo_required

  scope :for_company, ->(company_id) { joins(:user).where(users: { company_id: company_id }) }
  scope :pending_for_manager, ->(manager_id) {
    joins(:user).where(users: { manager_id: manager_id }).pending
  }

  has_paper_trail meta: {
    company_id: ->(la) { la.user&.company_id },
    status_change: ->(la) { la.status_previously_changed? ? la.status : nil }
  }

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end

  def extended_reason_if_ceo_required
    return unless requires_ceo_approval?
    errors.add(:extended_reason, "is required for extended leave") if extended_reason.blank?
  end
end
