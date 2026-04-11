class PublicHoliday < ApplicationRecord
  belongs_to :company

  validates :name, :holiday_date, :year, presence: true
  validates :holiday_date, uniqueness: { scope: :company_id }

  scope :for_year,      ->(year)       { where(year: year) }
  scope :mandatory,     ->             { where(is_mandatory: true) }
  scope :for_date_range,->(from, to)   { where(holiday_date: from..to) }

  has_paper_trail meta: { company_id: :company_id }
end
