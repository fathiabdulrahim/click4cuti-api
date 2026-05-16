class CareerProgress < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :manager, class_name: "User", optional: true, foreign_key: :manager_id
  belongs_to :department, optional: true

  validates :job_title, :effective_date, presence: true

  scope :for_user,   ->(uid) { where(user_id: uid).order(effective_date: :desc) }
  scope :for_company, ->(cid) { where(company_id: cid) }

  has_paper_trail meta: { company_id: :company_id }
end
