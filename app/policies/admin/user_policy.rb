module Admin
  class UserPolicy < ApplicationPolicy
    def index?   = true
    def show?    = true
    def create?  = true
    def update?  = true
    def destroy? = admin_user.super_admin? || admin_user.agency? || admin_user.company?

    class Scope < Scope
      def resolve
        case admin_user.scope
        when "SUPER_ADMIN" then scope.all
        when "AGENCY"      then scope.joins(:company).where(companies: { agency_id: admin_user.agency_id })
        when "COMPANY"     then scope.where(company_id: admin_user.company_id)
        else scope.none
        end
      end
    end
  end
end
