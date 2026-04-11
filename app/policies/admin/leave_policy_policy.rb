module Admin
  class LeavePolicyPolicy < ApplicationPolicy
    def index?   = true
    def show?    = true
    def create?  = admin_user.company? || admin_user.agency? || admin_user.super_admin?
    def update?  = admin_user.company? || admin_user.agency? || admin_user.super_admin?
    def destroy? = admin_user.company? || admin_user.agency? || admin_user.super_admin?

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
