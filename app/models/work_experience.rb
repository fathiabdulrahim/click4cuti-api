class WorkExperience < ApplicationRecord
  belongs_to :user

  validates :company_name, :position, :start_date, presence: true
  validate :end_date_after_start_date

  has_paper_trail meta: { company_id: ->(we) { we.user&.company_id } }

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end
end
