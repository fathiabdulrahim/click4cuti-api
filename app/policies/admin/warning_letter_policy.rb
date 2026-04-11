module Admin
  class WarningLetterPolicy < ApplicationPolicy
    def index?  = true
    def show?   = true
    def update? = true

    class Scope < Scope
      def resolve
        case admin_user.scope
        when "super_admin" then scope.all
        when "agency"      then scope.joins(:company).where(companies: { agency_id: admin_user.agency_id })
        when "company"     then scope.where(company_id: admin_user.company_id)
        else scope.none
        end
      end
    end
  end
end
