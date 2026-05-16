class ClaimType < ApplicationRecord
  belongs_to :company
  has_many :user_claim_policies, dependent: :destroy
  has_many :claim_applications, dependent: :restrict_with_error
  has_many :claim_balances, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :company_id }

  scope :active, -> { where(is_active: true) }
  scope :for_company, ->(cid) { where(company_id: cid) }

  has_paper_trail meta: { company_id: :company_id }
end
