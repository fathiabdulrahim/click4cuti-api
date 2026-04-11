module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        # Disable public registration — users are created by admins only
        def create
          render json: { error: "Registration is not available. Contact your administrator." },
                 status: :forbidden
        end
      end
    end
  end
end
