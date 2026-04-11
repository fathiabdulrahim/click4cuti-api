module Api
  module V1
    module Admin
      class ActivityLogsController < BaseController
        def index
          logs = policy_scope(ActivityLog).recent.limit(200)
          render json: logs.as_json(only: %i[id actor_id actor_type company_id action entity_type entity_id details ip_address created_at])
          skip_authorization
        end
      end
    end
  end
end
