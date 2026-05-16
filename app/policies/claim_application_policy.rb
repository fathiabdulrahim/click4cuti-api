class ClaimApplicationPolicy < ApplicationPolicy
  def index?   = true
  def show?    = own? || manages? || user.admin?
  def create?  = user.company_id == record.user.company_id
  def update?  = own? && record.status == "PENDING"
  def destroy? = own? && record.status == "PENDING"
  def cancel?  = update?
  def approve? = manages?  || user.admin?
  def reject?  = approve?

  class Scope < Scope
    def resolve
      scope.joins(:user).where(users: { company_id: user.company_id })
    end
  end

  private

  def own?
    record.user_id == user.id
  end

  def manages?
    return false unless record.user.company_id == user.company_id
    return true  if user.admin?
    user.subordinates.exists?(id: record.user_id)
  end
end
