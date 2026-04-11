class TeamRequestPolicy < ApplicationPolicy
  def index?  = user.manager? || user.admin?
  def update? = user.manager? || user.admin?
  def approve? = user.manager? || user.admin?

  class Scope < Scope
    def resolve
      if user.admin?
        scope.for_company(user.company_id)
      elsif user.manager?
        scope.joins(:user).where(users: { manager_id: user.id })
      else
        scope.none
      end
    end
  end
end
