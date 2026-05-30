class TeamRequestPolicy < ApplicationPolicy
  def index?   = true
  def show?    = approve?
  def update?  = approve?
  def coverage? = approve?
  def approve? = LeaveApplicationPolicy.new(user, record).approve?

  class Scope < Scope
    def resolve
      if user.admin?
        scope.for_company(user.company_id).where.not(user_id: user.id)
      else
        ids = approvable_user_ids
        return scope.none if ids.empty?
        scope.where(user_id: ids)
      end
    end

    private

    def approvable_user_ids
      explicit_ids = user.approver_for.pluck(:id)
      fallback_ids = User.where(manager_id: user.id)
                         .where.not(id: UserLeaveApprover.select(:user_id))
                         .pluck(:id)
      (explicit_ids + fallback_ids).uniq - [ user.id ]
    end
  end
end