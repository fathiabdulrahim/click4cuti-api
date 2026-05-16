class LeaveApplicationPolicy < ApplicationPolicy
  # NOTE: This policy governs the employee-facing /api/v1/team_requests endpoint
  # (current_user is a User). AdminUsers approve via the /api/v1/admin/leave_applications
  # namespace, which has its own policy — even though LeaveApplication.approver is
  # polymorphic at the data layer, only Users can be assigned via UserLeaveApprover.
  def index?   = true
  def show?    = Scope.new(user, LeaveApplication).resolve.exists?(id: record.id)
  def create?  = user.employee? || user.manager? || user.admin?
  def update?  = record.user_id == user.id && record.pending?
  def destroy? = record.user_id == user.id && record.pending?

  def approve?
    return false if record.user_id == user.id
    return true  if user.admin? && record.user.company_id == user.company_id

    applicant_approver_ids = record.user.leave_approver_ids
    if applicant_approver_ids.any?
      applicant_approver_ids.include?(user.id)
    else
      record.user.manager_id == user.id
    end
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.for_company(user.company_id)
      else
        scope.where(user_id: visible_user_ids)
      end
    end

    private

    def visible_user_ids
      explicit_ids = user.approver_for.pluck(:id)
      fallback_ids = User.where(manager_id: user.id)
                         .where.not(id: UserLeaveApprover.select(:user_id))
                         .pluck(:id)
      ([ user.id ] + explicit_ids + fallback_ids).uniq
    end
  end
end
