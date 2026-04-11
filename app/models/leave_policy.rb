class LeavePolicy < ApplicationRecord
  belongs_to :company
  has_many :leave_types, dependent: :destroy
  has_many :user_leave_policies, dependent: :destroy
  has_many :users, through: :user_leave_policies

  validates :name, :company, presence: true

  scope :active, -> { where(is_active: true) }

  has_paper_trail meta: { company_id: :company_id }
end
