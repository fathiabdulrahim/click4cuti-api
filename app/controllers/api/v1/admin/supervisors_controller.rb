module Api
  module V1
    module Admin
      class SupervisorsController < BaseController
        before_action :set_user
        before_action :set_assignment, only: [ :update, :destroy ]

        def index
          records = policy_scope(UserSupervisor).where(user_id: @user.id)
          render json: UserSupervisorBlueprint.render(records)
        end

        def create
          @assignment = UserSupervisor.new(assignment_params.merge(user_id: @user.id))
          authorize @assignment
          if @assignment.save
            log_activity("user_supervisor.create", @assignment)
            render json: UserSupervisorBlueprint.render(@assignment), status: :created
          else
            render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          authorize @assignment
          if @assignment.update(assignment_params.except(:user_id))
            log_activity("user_supervisor.update", @assignment)
            render json: UserSupervisorBlueprint.render(@assignment)
          else
            render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @assignment
          @assignment.destroy!
          log_activity("user_supervisor.destroy", @assignment)
          head :no_content
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def set_assignment
          @assignment = UserSupervisor.find(params[:id])
        end

        def assignment_params
          params.require(:supervisor).permit(:supervisor_id, :category, :level)
        end
      end
    end
  end
end
