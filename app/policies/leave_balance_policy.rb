class LeaveBalancePolicy < ApplicationPolicy
  def index? = true

  class Scope < Scope
    def resolve
      if user.admin?
        scope.joins(:user).where(users: { company_id: user.company_id })
      elsif user.manager?
        scope.joins(:user).where(users: { id: [user.id] + user.managed_user_ids })
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
