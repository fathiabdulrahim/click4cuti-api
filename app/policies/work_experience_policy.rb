class WorkExperiencePolicy < ApplicationPolicy
  def index?   = true
  def show?    = same_company?
  def create?  = same_company?
  def update?  = same_company?
  def destroy? = same_company?

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
