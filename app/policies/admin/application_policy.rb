module Admin
  class ApplicationPolicy
    attr_reader :admin_user, :record

    def initialize(admin_user, record)
      @admin_user = admin_user
      @record     = record
    end

    def index?   = false
    def show?    = false
    def create?  = false
    def update?  = false
    def destroy? = false

    class Scope
      def initialize(admin_user, scope)
        @admin_user = admin_user
        @scope      = scope
      end

      def resolve
        raise NotImplementedError
      end

      private

      attr_reader :admin_user, :scope
    end
  end
end
