class Branch < ApplicationRecord
  belongs_to :company
  has_many :users, dependent: :nullify

  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
  scope :for_company, ->(company_id) { where(company_id: company_id) }

  has_paper_trail meta: { company_id: :company_id }
end
