class LeaveApplicationPolicy < ApplicationPolicy
  def index?   = true
  def show?    = Scope.new(user, LeaveApplication).resolve.exists?(id: record.id)
  def create?  = user.employee? || user.manager? || user.admin?
  def update?  = record.user_id == user.id && record.pending?
  def destroy? = record.user_id == user.id && record.pending?

  def approve?
    return true if user.admin?
    user.manager? && record.user.manager_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.for_company(user.company_id)
      elsif user.manager?
        scope.joins(:user).where(users: { id: [user.id] + user.managed_user_ids })
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
