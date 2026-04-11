module Admin
  class LeaveTypePolicy < ApplicationPolicy
    def index?   = true
    def show?    = true
    def create?  = admin_user.company? || admin_user.agency? || admin_user.super_admin?
    def update?  = admin_user.company? || admin_user.agency? || admin_user.super_admin?
    def destroy? = admin_user.company? || admin_user.agency? || admin_user.super_admin?

    class Scope < Scope
      def resolve
        case admin_user.scope
        when "super_admin" then scope.all
        when "agency"      then scope.joins(leave_policies: :company).where(companies: { agency_id: admin_user.agency_id })
        when "company"     then scope.joins(:leave_policies).where(leave_policies: { company_id: admin_user.company_id })
        else scope.none
        end
      end
    end
  end
end
