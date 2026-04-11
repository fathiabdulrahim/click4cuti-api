module Admin
  class CompanyPolicy < ApplicationPolicy
    def index?   = admin_user.super_admin? || admin_user.agency?
    def show?    = admin_user.super_admin? || admin_user.agency? || admin_user.company?
    def create?  = admin_user.super_admin? || admin_user.agency?
    def update?  = admin_user.super_admin? || admin_user.agency? || (admin_user.company? && record.id == admin_user.company_id)
    def destroy? = admin_user.super_admin?

    class Scope < Scope
      def resolve
        case admin_user.scope
        when "super_admin" then scope.all
        when "agency"      then scope.where(agency_id: admin_user.agency_id)
        when "company"     then scope.where(id: admin_user.company_id)
        else scope.none
        end
      end
    end
  end
end
