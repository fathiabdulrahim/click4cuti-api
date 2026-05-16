class UserClaimPolicy < ApplicationRecord
  belongs_to :user
  belongs_to :claim_type

  validates :user_id, uniqueness: { scope: :claim_type_id }

  scope :included, -> { where(is_included: true) }

  has_paper_trail meta: { company_id: ->(p) { p.user&.company_id } }
end
