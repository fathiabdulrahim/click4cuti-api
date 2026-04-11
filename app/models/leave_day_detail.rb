class LeaveDayDetail < ApplicationRecord
  belongs_to :leave_application

  enum :day_type, {
    full_day:    "FULL_DAY",
    half_day_am: "HALF_DAY_AM",
    half_day_pm: "HALF_DAY_PM"
  }

  validates :leave_date, :day_type, presence: true
  validates :leave_date, uniqueness: { scope: :leave_application_id }

  def day_value
    full_day? ? 1.0 : 0.5
  end
end
