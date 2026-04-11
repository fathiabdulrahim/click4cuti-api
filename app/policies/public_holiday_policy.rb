class PublicHolidayPolicy < ApplicationPolicy
  def index? = true

  class Scope < Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end
