class WarningLetter < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :leave_type

  validates :reason, :year, :issued_date, presence: true

  scope :for_year, ->(year) { where(year: year) }
  scope :unacknowledged, -> { where(acknowledged: false) }

  has_paper_trail meta: { company_id: :company_id }
end
