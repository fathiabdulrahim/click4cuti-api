module Api
  module V1
    module Admin
      module Auth
        class SessionsController < Devise::SessionsController
          respond_to :json

          private

          def respond_with(resource, _opts = {})
            render json: {
              message: "Admin logged in successfully.",
              admin_user: {
                id:         resource.id,
                email:      resource.email,
                full_name:  resource.full_name,
                scope:      resource.scope_before_type_cast,
                agency_id:  resource.agency_id,
                company_id: resource.company_id
              }
            }, status: :ok
          end

          def respond_to_on_destroy(*)
            render json: { message: "Logged out successfully." }, status: :ok
          end
        end
      end
    end
  end
end
