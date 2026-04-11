module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_admin_user!
        after_action :verify_authorized, except: :index
        after_action :verify_policy_scoped, only: :index

        private

        def pundit_user
          current_admin_user
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
