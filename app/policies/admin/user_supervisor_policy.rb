module Admin
  class UserSupervisorPolicy < ApplicationPolicy
    def index?   = true
    def show?    = true
    def create?  = true
    def update?  = true
    def destroy? = true

    class Scope < Scope
      def resolve
        case admin_user.scope
        when "super_admin" then scope.all
        when "agency"      then scope.joins(:user).where(users: { company_id: company_ids_in_agency })
        when "company"     then scope.joins(:user).where(users: { company_id: admin_user.company_id })
        else scope.none
        end
      end

      private

      def company_ids_in_agency
        Company.where(agency_id: admin_user.agency_id).select(:id)
      end
    end
  end
end
