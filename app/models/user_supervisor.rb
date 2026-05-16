class UserSupervisor < ApplicationRecord
  LEVELS = [ 1, 2 ].freeze

  belongs_to :user
  belongs_to :supervisor, class_name: "User"

  enum :category, {
    leave:    "LEAVE",
    claim:    "CLAIM",
    overtime: "OVERTIME",
    timeoff:  "TIMEOFF"
  }, prefix: :category

  validates :level, inclusion: { in: LEVELS }
  validates :user_id, uniqueness: { scope: [ :category, :level ] }
  validate :no_self_assignment

  scope :level_1, -> { where(level: 1) }
  scope :level_2, -> { where(level: 2) }

  has_paper_trail meta: { company_id: ->(us) { us.user&.company_id } }

  private

  def no_self_assignment
    errors.add(:supervisor_id, "cannot be the same as user") if user_id == supervisor_id
  end
end
