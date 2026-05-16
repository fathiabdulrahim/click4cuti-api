class ClaimBalancePolicy < ApplicationPolicy
  def index? = true
  def show?  = same_company?

  class Scope < Scope
    def resolve
      scope.joins(:user).where(users: { company_id: user.company_id })
    end
  end

  private

  def same_company?
    record.user.company_id == user.company_id
  end
end
