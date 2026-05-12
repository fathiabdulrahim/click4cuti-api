class UserLeaveApprover < ApplicationRecord
  belongs_to :user
  belongs_to :approver, class_name: "User"

  validates :user_id, uniqueness: { scope: :approver_id }
  validate  :approver_in_same_company
  validate  :approver_is_not_self

  private

  def approver_in_same_company
    return if user.blank? || approver.blank?
    errors.add(:approver, "must belong to the same company") if user.company_id != approver.company_id
  end

  def approver_is_not_self
    errors.add(:approver, "cannot be the user themselves") if user_id == approver_id
  end
end
