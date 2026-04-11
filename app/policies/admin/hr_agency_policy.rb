module Admin
  class HrAgencyPolicy < ApplicationPolicy
    def index?   = admin_user.super_admin?
    def show?    = admin_user.super_admin?
    def create?  = admin_user.super_admin?
    def update?  = admin_user.super_admin?
    def destroy? = admin_user.super_admin?

    class Scope < Scope
      def resolve
        admin_user.super_admin? ? scope.all : scope.none
      end
    end
  end
end
