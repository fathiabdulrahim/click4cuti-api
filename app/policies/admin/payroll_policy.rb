module Admin
  class PayrollPolicy < ApplicationPolicy
    def show?    = admin_user.scope.in?(%w[super_admin agency company])
    def update?  = show?
  end
end
