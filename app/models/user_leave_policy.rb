class UserLeavePolicy < ApplicationRecord
  belongs_to :user
  belongs_to :leave_policy

  validates :effective_from, presence: true

  scope :current, -> { where(effective_to: nil) }
  scope :active_on, ->(date) {
    where("effective_from <= ?", date)
      .where("effective_to IS NULL OR effective_to >= ?", date)
  }
end
