module Api
  module V1
    class WorkExperiencesController < BaseController
      before_action :set_work_experience, only: [ :show, :update, :destroy ]

      def index
        records = policy_scope(WorkExperience).where(user_id: current_user.id).order(start_date: :desc)
        render json: WorkExperienceBlueprint.render(records)
      end

      def show
        authorize @work_experience
        render json: WorkExperienceBlueprint.render(@work_experience, view: :detail)
      end

      def create
        @work_experience = current_user.work_experiences.new(work_experience_params)
        authorize @work_experience
        if @work_experience.save
          log_activity("work_experience.create", @work_experience)
          render json: WorkExperienceBlueprint.render(@work_experience), status: :created
        else
          render json: { errors: @work_experience.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @work_experience
        if @work_experience.update(work_experience_params)
          log_activity("work_experience.update", @work_experience)
          render json: WorkExperienceBlueprint.render(@work_experience)
        else
          render json: { errors: @work_experience.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @work_experience
        @work_experience.destroy!
        log_activity("work_experience.destroy", @work_experience)
        head :no_content
      end

      private

      def set_work_experience
        @work_experience = WorkExperience.find(params[:id])
      end

      def work_experience_params
        params.require(:work_experience).permit(:company_name, :position, :start_date, :end_date)
      end
    end
  end
end
