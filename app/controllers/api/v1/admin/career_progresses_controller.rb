module Api
  module V1
    module Admin
      class CareerProgressesController < BaseController
        before_action :set_user
        before_action :set_career_progress, only: [ :show, :update, :destroy ]

        def index
          records = policy_scope(CareerProgress).where(user_id: @user.id).order(effective_date: :desc)
          render json: CareerProgressBlueprint.render(records)
        end

        def show
          authorize @career_progress
          render json: CareerProgressBlueprint.render(@career_progress, view: :detail)
        end

        def create
          @career_progress = @user.career_progresses.new(career_progress_params.merge(company_id: @user.company_id))
          authorize @career_progress
          if @career_progress.save
            log_activity("career_progress.create", @career_progress)
            render json: CareerProgressBlueprint.render(@career_progress), status: :created
          else
            render json: { errors: @career_progress.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          authorize @career_progress
          if @career_progress.update(career_progress_params)
            log_activity("career_progress.update", @career_progress)
            render json: CareerProgressBlueprint.render(@career_progress)
          else
            render json: { errors: @career_progress.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @career_progress
          @career_progress.destroy!
          log_activity("career_progress.destroy", @career_progress)
          head :no_content
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def set_career_progress
          @career_progress = CareerProgress.find(params[:id])
        end

        def career_progress_params
          params.require(:career_progress).permit(
            :job_title, :effective_date, :manager_id, :department_id, :job_type, :description
          )
        end
      end
    end
  end
end
