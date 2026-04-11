class LeaveType < ApplicationRecord
  belongs_to :leave_policy
  belongs_to :shared_balance, class_name: "LeaveType", optional: true, foreign_key: :shared_balance_with

  has_many :leave_balances,     dependent: :destroy
  has_many :leave_applications, dependent: :restrict_with_error
  has_many :warning_letters,    dependent: :nullify
  has_many :dependent_leave_types, class_name: "LeaveType", foreign_key: :shared_balance_with, dependent: :nullify

  enum :category, { mandatory: "MANDATORY", special: "SPECIAL" }

  validates :name, :category, presence: true

  scope :active, -> { where(is_active: true) }

  has_paper_trail
end
