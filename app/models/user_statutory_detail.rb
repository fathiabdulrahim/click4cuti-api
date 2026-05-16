class UserStatutoryDetail < ApplicationRecord
  belongs_to :user

  enum :epf_contribution_start, {
    before_1998_aug: "BEFORE_1998_AUG",
    after_1998_aug:  "AFTER_1998_AUG",
    after_2001_aug:  "AFTER_2001_AUG"
  }, prefix: :epf_start

  validates :user_id, uniqueness: true
  validates :eis_employee_rate, :eis_employer_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1, allow_nil: true }

  has_paper_trail meta: { company_id: ->(s) { s.user&.company_id } }
end
