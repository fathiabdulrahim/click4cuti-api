class WarningLetter < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :leave_type, optional: true
  belongs_to :issued_by, polymorphic: true, optional: true

  has_one_attached :supporting_document

  enum :source, { auto: "AUTO", manual: "MANUAL" }, prefix: :source

  validates :reason, :year, :issued_date, presence: true
  validates :leave_type_id, presence: true, if: :source_auto?

  scope :for_year, ->(year) { where(year: year) }
  scope :unacknowledged, -> { where(acknowledged: false) }

  has_paper_trail meta: { company_id: :company_id }
end
