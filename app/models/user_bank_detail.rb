class UserBankDetail < ApplicationRecord
  belongs_to :user

  enum :account_type, {
    saving:  "SAVING",
    current: "CURRENT",
    fixed:   "FIXED",
    others:  "OTHERS"
  }, prefix: :account_type

  enum :account_status, {
    active:   "ACTIVE",
    inactive: "INACTIVE"
  }, prefix: :account

  validates :user_id, uniqueness: true

  has_paper_trail meta: { company_id: ->(b) { b.user&.company_id } }
end
