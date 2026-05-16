class ClaimApplication < ApplicationRecord
  belongs_to :user
  belongs_to :claim_type
  belongs_to :approver, polymorphic: true, optional: true
  has_many :claim_documents, dependent: :destroy

  enum :status, {
    pending:   "PENDING",
    approved:  "APPROVED",
    rejected:  "REJECTED",
    cancelled: "CANCELLED"
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :claim_date, :reason, presence: true

  scope :for_user, ->(uid) { where(user_id: uid) }
  scope :for_year, ->(year) { where("EXTRACT(YEAR FROM claim_date) = ?", year) }

  has_paper_trail meta: { company_id: ->(c) { c.user&.company_id } }
end
