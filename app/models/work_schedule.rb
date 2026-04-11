class WorkSchedule < ApplicationRecord
  belongs_to :company
  has_many :user_work_schedules, dependent: :destroy
  has_many :users, through: :user_work_schedules

  validates :name, :start_time, :end_time, :rest_days, presence: true

  scope :active, -> { where(is_active: true) }

  def rest_days_array
    rest_days.to_s.split(",").map(&:strip)
  end

  has_paper_trail
end
