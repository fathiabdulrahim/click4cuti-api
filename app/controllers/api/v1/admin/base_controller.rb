module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_admin_user!
        after_action :verify_authorized, unless: -> { action_name == "index" }
        after_action :verify_policy_scoped, if: -> { action_name == "index" }

        private

        def pundit_user
          current_admin_user
        end

        def authorize(record, query = nil, policy_class: nil)
          policy_class ||= admin_policy_class(record)
          super(record, query, policy_class: policy_class)
        end

        def policy_scope(scope, policy_scope_class: nil)
          klass = scope.is_a?(Class) ? scope : scope.klass
          policy_scope_class ||= "Admin::#{klass.name}Policy::Scope".constantize
          super(scope, policy_scope_class: policy_scope_class)
        end

        def admin_policy_class(record)
          name = case record
                 when Symbol then record.to_s.camelize
                 when Class  then record.name
                 else record.class.name
                 end
          "Admin::#{name}Policy".constantize
        end

        def log_activity(action, entity = nil)
          ActivityLog.create!(
            actor_id:    current_admin_user.id,
            actor_type:  "AdminUser",
            company_id:  current_admin_user.company_id,
            action:      action,
            entity_type: entity&.class&.name,
            entity_id:   entity&.id,
            ip_address:  request.remote_ip
          )
        end
      end
    end
  end
end
