module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          render json: {
            message: "Logged in successfully.",
            user: {
              id:         resource.id,
              email:      resource.email,
              full_name:  resource.full_name,
              role:       resource.role,
              company_id: resource.company_id
            }
          }, status: :ok
        end

        def respond_to_on_destroy
          render json: { message: "Logged out successfully." }, status: :ok
        end
      end
    end
  end
end
