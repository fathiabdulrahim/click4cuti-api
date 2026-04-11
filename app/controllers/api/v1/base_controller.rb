module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tenant_scope
      after_action :verify_authorized, unless: -> { action_name == "index" }
      after_action :verify_policy_scoped, if: -> { action_name == "index" }

      private

      def set_tenant_scope
        @current_company = current_user.company
      end

      def current_company
        @current_company
      end

      def log_activity(action, entity = nil)
        ActivityLog.create!(
          actor_id:    current_user.id,
          actor_type:  "User",
          company_id:  current_company&.id,
          action:      action,
          entity_type: entity&.class&.name,
          entity_id:   entity&.id,
          ip_address:  request.remote_ip
        )
      end
    end
  end
end
