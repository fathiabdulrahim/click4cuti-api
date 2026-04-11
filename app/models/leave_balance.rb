class LeaveBalance < ApplicationRecord
  belongs_to :user
  belongs_to :leave_type

  validates :year, :total_entitled, presence: true
  validates :year, uniqueness: { scope: [:user_id, :leave_type_id] }

  scope :for_year, ->(year) { where(year: year) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  has_paper_trail meta: {
    company_id: ->(lb) { lb.user&.company_id }
  }

  def recalculate_remaining!
    update!(remaining_days: total_entitled + carried_forward - used_days - pending_days)
  end
end
